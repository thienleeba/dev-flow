# /dev-morning — follow-ups (DevFlow)

Read this only when the user replies to the morning list. Use the data already collected in this conversation; re-run `bash ../../shared/scripts/collect.sh --print` only if it is older than 1 hour.

## When the user replies

- **A PR or issue number** (e.g. `412`) → plan just that item the `/dev-plan` way: read `.devflow/workflows.md` (or run `bash ../../shared/scripts/discover.sh` and write it as `/dev-plan` does), show the one task with its `↳` action, and ask **go**. On go, follow `../plan/run.md` for **that task only** (`go #<n>`), never the rest of today's plan. Nothing runs before go.
- **more** → show the full view below.

## Full view (for "more")

Same style as the to-do list: bold icon headings, `- ` bullets, linked `#n`, everything listed (no "+N more").

```markdown
☀️ **Everything · shop-api · Tue 13 Oct**

**❌ My PRs — fix**
- [#412](https://github.com/o/r/pull/412#discussion) Fix double charge on retry — CI ❌ `test`

**💬 My PRs — reply**
- [#405](https://github.com/o/r/pull/405#discussion) Limit upload size — 1 open thread · @bob

**👀 My PRs — in review**
- [#392](https://github.com/o/r/pull/392#discussion) Two-factor login for admins — waiting on @dave · CI ✅

**🟢 My PRs — no reviewer yet**
- [#360](https://github.com/o/r/pull/360#discussion) Move images to CDN — open 20d · CI ✅

**⚫ My PRs — draft**
- [#415](https://github.com/o/r/pull/415#discussion) Export orders as CSV — CI ⏳

**🟣 My PRs — merged to dev, verify**
- [#350](https://github.com/o/r/pull/350#discussion) Order history pagination — merged today

**👀 To review (18)** — smallest and oldest first, drafts last
- [#401](https://github.com/o/r/pull/401#discussion) Bump express 4 → 5 — dependabot · +1 · CI ❌ `build`
- [#398](https://github.com/o/r/pull/398#discussion) Rate-limit login API — @alice · +238 · 5d

**💬 Needs my answer**
- [#377](https://github.com/o/r/pull/377#discussion) Which events to audit-log — needs-decision

**🟢 Assigned to me, not started** — high → low
- [#380](https://github.com/o/r/pull/380#discussion) Refund webhook retries — bug

**⚫ New issues, nobody assigned (21)** — high → low
- [#410](https://github.com/o/r/pull/410#discussion) Checkout fails for some cards — High · 2d
- [#411](https://github.com/o/r/pull/411#discussion) Add dark mode to admin — P3 · 1d

**🧹 Local cleanup**
- dev 70 commits behind — `git switch dev && git pull`
- 218 gone branches · 4 prunable worktrees · 33 stashes — ask before deleting

→ Reply with a number (e.g. **412**) to start.
```

PR status order (first that applies): ❌ conflict / CI failing (`check`) / changes requested · 💬 comments to reply · ✅ approved, ready to merge · 👀 in review · 🟢 no reviewer yet · ⚫ draft · 🟣 merged to `<base>` — verify · 🔴 closed. CI: ✅ passing · ❌ failing `check` · ⏳ running. Empty groups are left out.
