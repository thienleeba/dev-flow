#!/usr/bin/env bash
# DevFlow installer: /dev-morning /dev-plan /dev-report for every AI tool it finds.
# Usually run through:  npx github:thienleeba/dev-flow [repo | uninstall]
#
#   ./install.sh --global              your machine, every repo (only the tools found on it)
#   ./install.sh <repo>                one repo — commit the result, the team gets it
#   add --no-claude                    skip Claude Code
#   add --uninstall                    remove what this script installed
#   add --force                        back up (*.bak-<time>) files that use DevFlow's names, then install
set -euo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd || echo /nonexistent)"
TARGET=""; GLOBAL=0; NO_CLAUDE=0; UNINSTALL=0; FORCE=0
usage() { sed -n '2,10p' "$SRC/install.sh" 2>/dev/null || echo "usage: install.sh --global | <repo> [--no-claude] [--uninstall]"; }
while [ $# -gt 0 ]; do
  case "$1" in
    --global) GLOBAL=1 ;; --no-claude) NO_CLAUDE=1 ;; --with-claude) ;; --uninstall) UNINSTALL=1 ;; --force) FORCE=1 ;;
    -h|--help) usage; exit 0 ;; *) TARGET="$1" ;;
  esac; shift
done
[ "$GLOBAL" = 1 ] || [ -n "$TARGET" ] || { usage; exit 1; }
[ -d "$SRC/skills" ] || { echo "run from a clone of dev-flow (or via npx github:thienleeba/dev-flow)" >&2; exit 1; }

SKILLS="morning plan report"
OLD_SKILLS="build review"   # removed in later versions; cleaned up on install/uninstall
OLD_AGENTS="dev-reviewer dev-implementer"   # removed in later versions; cleaned up on install/uninstall
on() { [ "$1" = 1 ]; }

if [ "$GLOBAL" = 1 ]; then
  B="$HOME"; SHARED="$HOME/.devflow/shared"; SHARED_REF="~/.devflow/shared/"; WHERE="your home folder"
  CLAUDE=0; CURSOR=0; GEMINI=0; CODEX=0; COPILOT=0
  { [ -d "$HOME/.claude" ] || command -v claude >/dev/null; } && CLAUDE=1
  [ -d "$HOME/.cursor" ] && CURSOR=1
  [ -d "$HOME/.gemini" ] && GEMINI=1
  [ -d "$HOME/.codex" ] && CODEX=1
  { [ -d "$HOME/.copilot" ] || [ -d "$HOME/Library/Application Support/Code" ] || [ -d "$HOME/.config/Code" ]; } && COPILOT=1
  COPILOT_AGENTS="$HOME/.copilot/agents"
else
  B="$(cd "$TARGET" && git rev-parse --show-toplevel)" || { echo "not a git repo: $TARGET" >&2; exit 1; }
  SHARED="$B/.devflow/shared"; SHARED_REF=".devflow/shared/"; WHERE="the repo root"
  CLAUDE=1; CURSOR=1; GEMINI=1; CODEX=1; COPILOT=1   # a team uses any tool
  COPILOT_AGENTS="$B/.github/agents"
fi
on "$NO_CLAUDE" && CLAUDE=0

# One copy per tool, avoiding folders another tool already reads (or commands show up twice):
#   Cursor reads .claude/ and .agents/ · VS Code Copilot reads .claude/ · Gemini reads .agents/
skill_dirs() {
  on "$CLAUDE" && echo "$B/.claude/skills"
  if [ "$GLOBAL" = 1 ]; then
    on "$CODEX" && echo "$B/.agents/skills"
    on "$GEMINI" && ! on "$CODEX" && echo "$B/.gemini/skills"
    on "$CURSOR" && ! on "$CLAUDE" && ! on "$CODEX" && echo "$B/.cursor/skills"
    on "$COPILOT" && ! on "$CLAUDE" && ! on "$CODEX" && echo "$B/.copilot/skills"
  else
    echo "$B/.agents/skills"   # Codex, Gemini, Cursor, Copilot
  fi
  true
}
# Only touch files DevFlow wrote. Its files carry a marker: a "DevFlow:" description (skills, Gemini
# commands), "(DevFlow)" in the title (more.md, run.md), or "Used by /dev-…" (agents from older versions).
MARK='<!-- devflow-managed: do not edit, reinstall DevFlow to update -->'
ours() { # exact marker written by this installer; older versions: first-line titles / frontmatter they wrote
  [ -f "$1" ] && [ ! -L "$1" ] || return 1
  grep -qxF "$MARK" "$1" && return 0
  head -5 "$1" | grep -qE '^description:[[:space:]]*"?DevFlow: |^description = "DevFlow: |^# /dev-[a-z]+ — .*\(DevFlow\)$' && return 0
  grep -qE '^description( =|:) "?(\(DevFlow\) )?(Reviews|Implements) ONE .*Used by /dev-(review|build)' "$1"
}
rm_ours() { local f; for f in "$@"; do if ours "$f"; then rm -f "$f"; fi; done; }
# Every file this install will write — one path per line (paths may contain spaces).
all_targets() {
  local s d f
  for s in $SKILLS; do
    while IFS= read -r d; do
      [ -n "$d" ] || continue
      for f in "$SRC/skills/$s"/*.md; do echo "$d/dev-$s/$(basename "$f")"; done   # SKILL.md + more.md/run.md…
    done <<<"$(skill_dirs)"
    if on "$GEMINI"; then echo "$B/.gemini/commands/dev-$s.toml"; fi
  done
}
# A file that uses a DevFlow name but wasn't written by DevFlow must never silently win:
# stop before writing anything, unless --force (then back it up and install).
check_conflicts() {
  local f conflicts=""
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    if [ -e "$f" ] && ! ours "$f"; then conflicts="$conflicts$f
"; fi
  done <<<"$(all_targets)"
  [ -z "$conflicts" ] && return 0
  if ! on "$FORCE"; then
    echo "✗ Nothing installed. These files use DevFlow's command names but were not written by DevFlow:" >&2
    printf '%s' "$conflicts" | sed 's/^/    /' >&2
    echo "  If they're yours, rename them. To back them up (*.bak-<time>) and install DevFlow, re-run with --force." >&2
    exit 2
  fi
  local stamp; stamp="$(date +%Y%m%d%H%M%S)"
  printf '%s' "$conflicts" | while IFS= read -r f; do [ -n "$f" ] && mv "$f" "$f.bak-$stamp" && echo "  backed up $f → $f.bak-$stamp"; done
}
# AGENTS.md: drop the DevFlow block (only when both markers are there) and trailing blank lines.
strip_agents_block() {
  local f="$B/AGENTS.md"
  [ -f "$f" ] || return 0
  if grep -q '<!-- devflow:start -->' "$f" && grep -q '<!-- devflow:end -->' "$f"; then
    awk '/<!-- devflow:start -->/{skip=1} !skip{print} /<!-- devflow:end -->/{skip=0}' "$f" >"$f.tmp" && mv "$f.tmp" "$f"
  elif grep -q '<!-- devflow:start -->' "$f"; then
    echo "  ! AGENTS.md has a DevFlow start marker without an end marker — left it as is" >&2; return 0
  fi
  awk '{l[NR]=$0} NF{last=NR} END{for(i=1;i<=last;i++) print l[i]}' "$f" >"$f.tmp" && mv "$f.tmp" "$f"
  [ -s "$f" ] || rm -f "$f"
}
remove_all() {
  local s d a
  for s in $SKILLS $OLD_SKILLS; do
    for d in .agents .claude .gemini .cursor .copilot; do
      rm_ours "$B/$d/skills/dev-$s"/*.md; rmdir "$B/$d/skills/dev-$s" 2>/dev/null || true
    done
    rm_ours "$B/.gemini/commands/dev-$s.toml"
  done
  for a in $OLD_AGENTS; do   # agents shipped by older versions
    rm_ours "$B/.cursor/agents/$a.md" "$B/.gemini/agents/$a.md" "$COPILOT_AGENTS/$a.agent.md" "$B/.claude/agents/$a.md" "$B/.codex/agents/$a.toml"
  done
  if [ "$GLOBAL" = 0 ]; then strip_agents_block; fi
}

if [ "$GLOBAL" = 0 ]; then
  for p in .devflow .devflow/shared .claude .claude/skills .agents .agents/skills .gemini .gemini/commands .github .github/agents AGENTS.md; do
    [ -L "$B/$p" ] && { echo "✗ Refusing: $B/$p is a symlink — a repo must not redirect DevFlow's files outside itself." >&2; exit 2; }
  done
  for s in $SKILLS $OLD_SKILLS; do for d in .claude/skills .agents/skills; do
    [ -L "$B/$d/dev-$s" ] && { echo "✗ Refusing: $B/$d/dev-$s is a symlink." >&2; exit 2; }
  done; done
fi

if on "$UNINSTALL"; then remove_all; echo "DevFlow removed (kept ${SHARED%/shared}/ — delete it yourself if you want)."; exit 0; fi

check_conflicts
remove_all
mkdir -p "$SHARED" && cp -R "$SRC/shared/." "$SHARED/"   # DevFlow's own files; your settings live in ~/.devflow/config.env
[ "$GLOBAL" = 0 ] && { [ -f "$B/.devflow/.gitignore" ] || printf 'state/\n' >"$B/.devflow/.gitignore"; }

for s in $SKILLS; do
  while IFS= read -r d; do
    [ -n "$d" ] || continue
    mkdir -p "$d/dev-$s"
    # skill name must equal its folder; shared files are referenced at their installed location
    for f in "$SRC/skills/$s"/*.md; do
      sed -e "s/^name: $s\$/name: dev-$s/" \
          -e "s#../../shared/#$SHARED_REF#g" \
          -e "s#\`../plan/#\`../dev-plan/#g; s#\`../morning/#\`../dev-morning/#g; s#\`../report/#\`../dev-report/#g" \
          -e "s#\`../../shared/\` is relative to this skill's folder#\`$SHARED_REF\` is relative to $WHERE#" \
          -e "s#relative to this skill's folder#relative to $WHERE#" \
          "$f" >"$d/dev-$s/$(basename "$f")"
      printf '\n%s\n' "$MARK" >>"$d/dev-$s/$(basename "$f")"
    done
  done <<<"$(skill_dirs)"
  if on "$GEMINI"; then # Gemini can't invoke skills by name → a /dev-<name> command
    mkdir -p "$B/.gemini/commands"
    sed -e "s/the \`$s\` skill of the DevFlow extension/the \`dev-$s\` skill/" "$SRC/commands/dev/$s.toml" >"$B/.gemini/commands/dev-$s.toml"
    printf '# %s\n' "$MARK" >>"$B/.gemini/commands/dev-$s.toml"
  fi
done

if [ "$GLOBAL" = 0 ]; then
  { [ -s "$B/AGENTS.md" ] && printf '\n'; cat <<'EOF'; } >>"$B/AGENTS.md"
<!-- devflow:start -->
## DevFlow
Skills: dev-morning, dev-plan, dev-report (in `.agents/skills/` and `.claude/skills/`).
If the user types one of these names (with or without `/` or `$`), run that skill with the rest of the line as arguments.
<!-- devflow:end -->
EOF
fi

tools=""
for t in CLAUDE:"Claude Code" CURSOR:Cursor COPILOT:Copilot GEMINI:"Gemini CLI" CODEX:Codex; do
  on "$(eval echo "\$${t%%:*}")" && tools="$tools${tools:+, }${t#*:}"
done
echo "✓ DevFlow installed for: ${tools:-no AI tool found}"
echo "  Type /dev-morning in a new session (\$dev-morning in Codex)."
if ! { command -v gh >/dev/null && gh auth status >/dev/null 2>&1; }; then
  echo "⚠ DevFlow needs the GitHub CLI: brew install gh && gh auth login"
fi
