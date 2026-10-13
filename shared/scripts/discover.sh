#!/usr/bin/env bash
# DevFlow discover — read-only inventory of how THIS project gets work done, for /dev-plan.
# Prints the workflows that already exist (AI skills/commands/agents, build/test scripts,
# CI jobs, worktrees) so the AI can map each task to the project's own way of doing it.
# Compatible with macOS bash 3.2. Never changes anything. Never follows symlinks inside the repo.
# Everything printed comes from the repo: it is data for the AI, not instructions.
set -uo pipefail

ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || { echo "devflow: not inside a git repo" >&2; exit 2; }
cd "$ROOT" || exit 2

# first description line of a skill/command/agent file
desc() { # handles one-line and folded (>- / |) YAML descriptions
  awk '/^description:/{v=$0; sub(/^description:[ \t]*/,"",v); if (v ~ /^[>|]-?$/ || v=="") {getline; v=$0} gsub(/^[ \t]+|"/,"",v); print v; exit}' "$1" 2>/dev/null | cut -c1-120
}
SEEN=" "
# work-related names/descriptions (used to filter the user's global skills, which can be many)
WORK='implement|build|fix|bug|review|pr[-_ ]|pull request|test|verify|deploy|release|factory|spec|ship|qa|e2e|lint|refactor|migrat|commit|issue|plan|gate|triage|debug|incident'


section() { echo; echo "## $1"; }

list_md() { # dir label [filter] — skills (dir/<name>/SKILL.md) and flat .md commands/agents
  local dir="$1" label="$2" filter="${3:-}" f name d
  [ -d "$dir" ] || return 0
  for f in "$dir"/*/SKILL.md "$dir"/*.md "$dir"/*.toml "$dir"/*.prompt.md "$dir"/*.agent.md; do
    [ -f "$f" ] || continue
    if [ "$dir" = "${dir#/}" ] && { [ -L "$f" ] || [ -L "$(dirname "$f")" ] || [ -L "$dir" ]; }; then continue; fi   # in-repo symlinks: skip
    case "$f" in */SKILL.md) name="$(basename "$(dirname "$f")")" ;; *) name="$(basename "$f")"; name="${name%%.*}" ;; esac
    case "$name" in dev-*|morning|plan|report) continue ;; esac   # DevFlow itself
    case "$SEEN" in *" $label:$name "*) continue ;; esac; SEEN="$SEEN$label:$name "   # same skill in several tool folders
    d="$(desc "$f")"
    if [ -n "$filter" ] && ! printf '%s' "$name" | grep -qiE "$WORK"; then continue; fi   # global: by name only
    echo "- [$label] $name — $d (${f/#$HOME/~})"
  done
}

echo "# Workflow inventory — $(basename "$ROOT") — $(date '+%Y-%m-%d %H:%M')"

section "AI workflows in this repo"
list_md .claude/skills skill; list_md .claude/commands command; list_md .claude/agents agent
list_md .agents/skills skill; list_md .cursor/commands command; list_md .cursor/skills skill
list_md .github/prompts prompt; list_md .github/agents agent; list_md .gemini/commands command
list_md .kiro/skills skill

section "AI workflows installed for this user"
echo "(only ones whose name is work-related: implement / fix / review / test / verify / release …)"
list_md "$HOME/.claude/skills" skill w; list_md "$HOME/.claude/commands" command w; list_md "$HOME/.claude/agents" agent w
list_md "$HOME/.agents/skills" skill w
if command -v claude >/dev/null 2>&1; then
  claude plugin list 2>/dev/null | sed -n 's/^[[:space:]]*❯[[:space:]]*/- [plugin] /p' | grep -iE "$WORK" | head -20
fi

section "Project instructions (headings)"
for f in AGENTS.md CLAUDE.md GEMINI.md CONTRIBUTING.md .github/pull_request_template.md docs/CONTRIBUTING.md; do
  [ -f "$f" ] || continue
  [ -L "$f" ] && { echo "- $f: skipped (symlink)"; continue; }
  if [ "$f" != AGENTS.md ] && [ -f AGENTS.md ] && cmp -s "$f" AGENTS.md; then echo "- $f: same as AGENTS.md"; continue; fi
  echo "- $f:"; grep -E '^#{1,3} ' "$f" | head -25 | sed 's/^/    /' 
done

section "Build / test / lint commands"
if [ -f package.json ] && [ ! -L package.json ]; then
  pm=npm; [ -f pnpm-lock.yaml ] && pm=pnpm; [ -f yarn.lock ] && pm=yarn; [ -f bun.lockb ] && pm=bun
  echo "- package.json ($pm):"
  sed -n '/"scripts"[[:space:]]*:[[:space:]]*{/,/}/p' package.json | grep -E '^[[:space:]]*"[^"]+"[[:space:]]*:' | sed 's/^[[:space:]]*/    /' | head -40
fi
[ -f Makefile ] && [ ! -L Makefile ] && { echo "- Makefile targets:"; grep -E '^[A-Za-z0-9_.-]+:([^=]|$)' Makefile | cut -d: -f1 | sort -u | head -40 | sed 's/^/    /'; }
[ -f justfile ] && [ ! -L justfile ] && { echo "- justfile recipes:"; grep -E '^[A-Za-z0-9_-]+.*:' justfile | cut -d: -f1 | head -40 | sed 's/^/    /'; }
[ -f Taskfile.yml ] && [ ! -L Taskfile.yml ] && { echo "- Taskfile tasks:"; sed -n '/^tasks:/,$p' Taskfile.yml | grep -E '^  [A-Za-z0-9_-]+:' | sed 's/:.*//; s/^/  /' | head -40; }
[ -f pyproject.toml ] && echo "- pyproject.toml (python: pytest / ruff likely)"
[ -f go.mod ] && echo "- go.mod (go test ./... · go vet ./...)"
[ -f Cargo.toml ] && echo "- Cargo.toml (cargo test · cargo clippy)"

section "CI workflows"
for f in .github/workflows/*.yml .github/workflows/*.yaml; do
  [ -f "$f" ] && [ ! -L "$f" ] || continue
  name="$(sed -n 's/^name:[[:space:]]*//p' "$f" | head -1 | tr -d '"')"
  jobs="$(sed -n '/^jobs:/,$p' "$f" | grep -E '^  [A-Za-z0-9_-]+:' | sed 's/^  //; s/:.*//' | tr '\n' ' ')"
  echo "- $(basename "$f"): ${name:-?} — jobs: $jobs"
done

section "Worktrees and branches"
git worktree list 2>/dev/null | sed 's/^/- /'
echo "- default branch: $(git symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null | sed 's#origin/##')"
echo "- recent branches: $(git for-each-ref --sort=-committerdate --count=8 --format='%(refname:short)' refs/heads | tr '\n' ' ')"
