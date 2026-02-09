---
name: auto-implement
description: "GitHub Issue -> Claude Code Agent Teams (Docker) -> PR -> Merge -> Cleanup."
user-invocable: true
metadata:
  {
    "openclaw":
      {
        "emoji": "🚀",
        "requires": { "bins": ["gh", "docker"] },
      },
  }
---

# Auto-Implement Pipeline

User request -> GitHub Issue -> Claude Code in Docker -> PR -> merge -> cleanup.

Container naming: `pipeline-<owner>-<repo>-<issue_number>` (for tracking/kill)
Status file: `/tmp/pipeline-<owner>-<repo>-<issue_number>.status` (JSON progress)

> **RULE: This is an automated pipeline. Execute each step immediately without asking for confirmation.
> The user already approved by requesting a feature/fix. Do NOT stop to ask "should I run it?" or "parallel or sequential?" — just execute.
> Only ask the user when: (1) the repo is unknown, or (2) the request is too ambiguous to create an issue.**

## Flow

### 1. Analyze Scope

Read `labels.md` and `repos.md` **in parallel**. Then:
1. **Check size** — is this a large feature needing multiple layers?
2. **Pick label** — or split into multiple issues if large.

If large feature → read `multi-issue.md` and follow the multi-issue flow instead of Steps 2-5.
If single issue → continue below.

### 2. Create Issue

Read `issue-template.md` for body format. (You already have `repos.md` from Step 1.) Follow the template strictly.

```bash
gh issue create --repo <owner/repo> --title "<concise English title>" --body "<details>" --label "<label>"
```

Ask user for repo only if not specified and not in `repos.md`.
After creation, send **Checkpoint 1** from `reporting.md`. Then immediately proceed to Step 3 — do NOT wait for user response.

### 3. Run Implementation

**Execute immediately after issue creation. Do NOT ask for confirmation.**

```bash
implement-issue.sh <owner/repo> <issue_number>
```

- Run in background exec. Takes 5-15 min.
- If multiple independent issues: run ALL of them in parallel (separate background exec per issue). Do NOT ask "parallel or sequential?" — independent issues always run in parallel.
- If issues depend on each other (multi-issue phases): run sequentially per `multi-issue.md`.
- Read `reporting.md` for polling strategy and progress updates.

### 4. Report Result

When the background exec completes, read the status file:
```bash
cat /tmp/pipeline-<owner>-<repo>-<issue_number>.status
```

Read `reporting.md` and send the appropriate checkpoint message:
- `status=success` -> **Checkpoint 3** (PR ready)
- `status=failed` -> **Checkpoint 4** (error + retry offer)

### 5. Merge + Cleanup

Read `cleanup.md` and follow the full procedure. Run merge, container kill, and orphan check **in parallel**. Do NOT skip container cleanup.
After merge, send **Checkpoint 5** from `reporting.md`.

```bash
gh pr merge <N> --repo <owner/repo> --rebase --delete-branch
```

### On cancel / status check

Read `cleanup.md` for cancel, abort, and status check flows.

## Reference Files

| File | Content | When to read |
|------|---------|-------------|
| `labels.md` | Size check, label criteria, examples | Step 1 |
| `repos.md` | Known repos, tech stacks | Step 1 (parallel with labels.md) |
| `multi-issue.md` | Split large features into phases | Step 1 (if large) |
| `issue-template.md` | Body strategy + template routing | Step 2 |
| `templates/<label>.md` | Label-specific body template | Step 2 (one file, per label) |
| `templates/sub-issue.md` | Multi-issue phase body template | Step 2 (if multi-issue) |
| `reporting.md` | Checkpoints, messages, polling, retry | Steps 2-5, on error |
| `cleanup.md` | Merge / cleanup / cancel / status | Step 5, on cancel |
| `errors.md` | Error scenarios and fixes | On error |
