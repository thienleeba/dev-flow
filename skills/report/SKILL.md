---
name: report
description: "DevFlow: daily report — what I did today, what I'll do next, issues that need action or confirmation. Run only when the user invokes it."
disable-model-invocation: true
---

# /dev-report — daily report

> Paths starting with `../../shared/` are relative to this skill's folder — resolve them to absolute paths before use. Files the command writes go to the current repo's `.devflow/`.

Goal: a daily report the developer can paste into the team chat as is. No arguments. If the user adds a date (`yesterday`, `2026-10-07`), report that day instead.

## 1. Collect facts

1. Read `../../shared/rules.md` and config (`../../shared/config.env`, then the repo's `.devflow/config.env` if present).
2. Run `bash ../../shared/scripts/collect.sh` (prefix `DEVFLOW_DAY=YYYY-MM-DD` for another day). Read `.devflow/state/snapshot.json` and `.devflow/state/local.txt`.
3. Local work not on GitHub yet: `git log --all --since="<day> 00:00" --until="<day> 23:59" --author="$(git config user.email)" --format="%h %s"`.
4. **Other trackers**: if a Jira, Linear or GitHub Projects tool/MCP is available in this session, also fetch: tickets assigned to me, tickets I moved or commented on that day, and their priority/status. If none is available, use GitHub only and don't mention it.
5. If today's plan exists (`.devflow/state/plan-<day>.md`), use it to spot planned work that didn't happen.

## 2. Build the three lists

**What I did** — from `today`: `prs_opened` and `prs_merged` (PRs I opened / mine that were merged that day), `prs_i_merged` (PRs I merged, e.g. a release PR opened by a bot), `reviews` I submitted, `issues_closed`, `commits_default_branch`, plus local commits and tracker transitions. Nothing else counts (an item updated by someone else is not your work).
- Group commits into the PR or issue they belong to; one bullet per piece of work, not per commit.
- Start with the reference, then what was achieved in plain words (≤ 12 words): `[#142](…) Fixed login timeout on mobile — merged`.
- Unfinished work counts if there were commits or a draft PR that day: `[#133](…) Search filter — ⏳ in progress, draft [#160](…)`. Never invent progress fractions.

**What I'll do next** — for the next working day (Friday → Monday):
1. Carry-over first: my PRs that need work (CI failing, changes requested, conflicts), unfinished in-progress issues/tickets, review requests waiting on me.
2. Then new work, highest priority first: tracker priority / project Priority field, else `priority_rank` (already the order of `assigned_issues`).
- Stop at what fits in `config.work_hours`; 3–6 bullets.

**Issues** — only things a human must act on, each with who/what is needed:
- *Needs my action*: failing CI on my PR, conflicts, a reviewer waiting on my reply, uncommitted or unpushed work.
- *Needs confirmation*: unclear scope/requirements (labels in `config.needs_input_labels`, open questions addressed to me), my PRs waiting for review > 2 days, decisions only the tech lead or PM can make. Say whom to ask if known (issue author, reviewer, `@mention`).
- Nothing → `- None`.

## 3. Output — exactly this, nothing before or after

```markdown
**✅ What I did today (Tue, 13 Oct 2026)**
- [#150](https://github.com/o/r/pull/150#discussion) Fixed lint failure on the export PR — merged
- [#155](https://github.com/o/r/pull/155#discussion) Reviewed "refactor auth" — requested changes
- [#133](https://github.com/o/r/issues/133#discussion) Search filter — ⏳ in progress, draft [#160](https://github.com/o/r/pull/160#discussion)

**🟢 What I'll do next (Wed, 14 Oct 2026)**
- [#133](https://github.com/o/r/issues/133#discussion) Finish search filter — tasks 5–6
- [#150](https://github.com/o/r/pull/150#discussion) Address review comments on export
- [#134](https://github.com/o/r/issues/134#discussion) Start cache headers — P1

**💬 Issues**
- [#160](https://github.com/o/r/pull/160#discussion) ❌ CI failing (`test`) — needs my action
- [#131](https://github.com/o/r/issues/131#discussion) 💬 Export filter scope — confirm with @pm
```

- Every bullet comes from a fact collected in step 1; nothing invented. No activity → `- No recorded activity` (don't pad).
- References are linked `#123` (rules §6), or the tracker key, e.g. `PROJ-42`; bullets are short and in plain language — this is read by people, not by git.
- Language: `config.language` if set, otherwise the user's.

Then save the same text to `.devflow/state/reports/<YYYY-MM-DD>.md` (silently).
