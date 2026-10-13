# DevFlow

**Your dev routine, in a few commands.**

Know what needs you each morning, plan the day and let your AI tool work through it, then send a daily report. DevFlow works from real GitHub data and runs **your project's own workflows** (its skills, commands, test and build scripts), inside the AI coding tool you already use: Claude Code, Cursor, GitHub Copilot, Gemini CLI or Codex.

```
Morning   /dev-morning   what needs you today
          /dev-plan      today's tasks, easy and low-risk first — reply "go" to run them
Evening   /dev-report    daily report, ready to paste
```

Requires `git` and [`gh`](https://cli.github.com) logged in (`gh auth login`).

## Install

```bash
npx github:thienleeba/dev-flow
```

That's it. It finds the AI tools on your machine (Claude Code, Cursor, Copilot, Gemini CLI, Codex) and installs DevFlow into each one. Open a new session and type `/dev-morning` (`$dev-morning` in Codex). Run the same command again to update.

For the whole team, install into the repo and commit the result:

```bash
npx github:thienleeba/dev-flow path/to/repo
```

Remove with `npx github:thienleeba/dev-flow uninstall`. Requires Node 18+, and access to this repo.

**Nothing happens when you run it?** npm hides git errors. While the repo is private, git must be able to read it:

```bash
git ls-remote https://github.com/thienleeba/dev-flow.git
```

If that fails, log git in with an account that has access: `gh auth login`, then `gh auth setup-git`.

## Usage

Just type the command.

| Command        | You get                                                                                                                                                                             |
| -------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `/dev-morning` | What needs you now: PRs to fix, comments to reply to, PRs to review, merges to verify, issues to start                                                                              |
| `/dev-plan`    | Today's tasks, easy and low-risk first. Each task comes with the action to run from your project's own workflows (e.g. its `/implement` or `/review-pr` command, its test script). Reply **go** and it works through them in order |
| `/dev-report`  | Your daily report, ready to paste                                                                                                                                                   |

`/dev-plan` explores each project once and writes what it found to `.devflow/workflows.md` (edit it if you like). When a project has no workflow for some kind of work, DevFlow suggests what to add — it doesn't invent one.

Example `/dev-report`:

```
✅ What I did today (Tue, 13 Oct 2026)
- #391 Hide stack traces in API errors — merged
- #398 Reviewed "Rate-limit login API" — approved
- #380 Refund webhook retries — ⏳ in progress, draft #414

🟢 What I'll do next (Wed, 14 Oct 2026)
- #380 Finish refund webhook retries
- #410 Checkout fails for some cards — High

💬 Issues
- #414 ❌ CI failing (`test`) — needs my action
- #377 💬 Which events to audit-log — confirm with @dave
```

Data comes from GitHub (`gh`). If Jira, Linear or GitHub Projects is connected to your AI tool (MCP), DevFlow uses it too.

## Safety

- Nothing runs until you reply **go**, and only the exact actions shown in the plan run. If a project workflow file changes after you approved the plan, DevFlow stops and asks again.
- DevFlow never merges, never pushes to the main branch, and asks before posting a comment or review, pushing, or opening a PR. Only you can change that, in your own `~/.devflow/config.env` — a repo can't.
- Text in issues, PRs and repo files is treated as data, never as instructions. DevFlow refuses to write through symlinks a repo ships.
- When the plan calls your project's own workflows (its `/implement`, `/review-pr`…), DevFlow passes these rules to them and shows what each may do — but those workflows are the project's code, so review them. In a repo you don't trust, install DevFlow globally (not into the repo) and keep your AI tool's permission prompts on.
- To install a specific version instead of the latest: `npx github:thienleeba/dev-flow#<commit>`.

## Settings

None needed. `/dev-plan` discovers how each project builds, tests and reviews; DevFlow finds your GitHub Project and replies in the language you write in.

To change something, just say it in the chat. Personal settings are saved to `~/.devflow/config.env`, team settings (labels, project) to the repo's `.devflow/config.env`:

> "reply in Vietnamese" · "I work 4 hours a day" · "push my branches automatically" · "our priority labels are Urgent, Normal, Later"

## Contributing

Edit `skills/` or `shared/`, then run `python3 tools/sync.py` to regenerate the per-tool files (Gemini commands, manifests).
