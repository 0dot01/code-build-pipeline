# Multi-Issue Orchestration (Large Features)

When a feature spans multiple layers (backend + frontend + tests + deploy), create a root issue with sub-issues for each phase.

## When to Split

Split if the feature requires **2 or more** of these:
- New API endpoints or DB schema changes
- New UI screens or significant component changes
- Integration tests or E2E tests
- Deploy/infra config changes (CI, env vars, etc.)

Do NOT split for:
- Single-layer work (just frontend, just backend)
- Simple features touching 1-5 files
- Bug fixes

## Structure

```
Root Issue #10: "Add payment system"          ← tracks overall feature
  ├── Sub-issue #11: Payment API + DB schema  ← Phase 1 (backend)
  ├── Sub-issue #12: Payment UI screens       ← Phase 2 (frontend)
  └── Sub-issue #13: Payment E2E tests        ← Phase 3 (tests)
```

Root issue is the tracker. Sub-issues are the work items that the pipeline runs.

## Phase order (always this sequence)

1. **Backend first** — API, DB, schema, server logic
2. **Frontend second** — UI that consumes the backend
3. **Tests third** — E2E / integration tests covering both layers
4. **Deploy/infra last** — CI, env vars, config (if needed)

Skip phases that don't apply. A feature needing only backend + frontend = 2 phases.

## Issue Creation

Read `templates/sub-issue.md` for the sub-issue body format. Use the Scope Boundary section to prevent phase overlap.

### Step 1: Create root issue (no auto-implement label)

```bash
gh issue create --repo <repo> \
  --title "Add payment system" \
  --body "## Overview
<feature description>

## Phases
- [ ] Phase 1: Payment API and DB schema
- [ ] Phase 2: Payment UI screens
- [ ] Phase 3: Payment E2E tests

Sub-issues will be created for each phase."
```

No `auto-implement` label on the root — it is a tracker, not a work item.

### Step 2: Create all sub-issues in parallel

Create all sub-issues **in parallel** (they only need the root issue number, not each other's numbers):

```bash
# Run ALL of these in parallel:

# Phase 1
gh issue create --repo <repo> \
  --title "[Payment] Phase 1: API and DB schema" \
  --body "## Parent
Part of #<root_issue_number>

## What
...

## Depends on
None (first phase)" \
  --label "auto-implement:backend"

# Phase 2 (parallel with Phase 1 creation)
gh issue create --repo <repo> \
  --title "[Payment] Phase 2: UI screens" \
  --body "## Parent
Part of #<root_issue_number>

## What
...

## Depends on
Phase 1 (created in parallel, link later)" \
  --label "auto-implement:frontend"

# Phase 3 (parallel with Phase 1 & 2 creation)
gh issue create --repo <repo> \
  --title "[Payment] Phase 3: E2E tests" \
  --body "## Parent
Part of #<root_issue_number>

## What
...

## Depends on
Phase 1 and Phase 2 (created in parallel, link later)" \
  --label "auto-implement"
```

Note: Sub-issue **creation** is parallel. Sub-issue **execution** is still sequential (Phase 1 must merge before Phase 2 runs).

### Step 3: Update root issue + start Phase 1 in parallel

Once all sub-issue numbers are known, run these **in parallel**:

1. Update root issue body with actual issue numbers
2. Start Phase 1 implementation

```bash
# Parallel task A: Update root issue
gh issue edit <root_issue_number> --repo <repo> \
  --body "## Overview
<feature description>

## Phases
- [ ] Phase 1: Payment API and DB schema #<phase1_number>
- [ ] Phase 2: Payment UI screens #<phase2_number>
- [ ] Phase 3: Payment E2E tests #<phase3_number>"

# Parallel task B: Start Phase 1
implement-issue.sh <repo> <phase1_number>
```

The task list checkboxes auto-track when sub-issues close.

## Execution Sequence

Sub-issue **creation** is parallel. Sub-issue **execution** is sequential (each phase must merge before the next starts).
Only run `implement-issue.sh` on sub-issues, never on the root issue.

```
Create root issue
  │
  ├─ Create all sub-issues ←── IN PARALLEL
  │
  ├─ IN PARALLEL:
  │   ├─ Update root issue with sub-issue links
  │   ├─ Report plan to user (with root issue URL)
  │   └─ Run Phase 1: implement-issue.sh <repo> <phase1_number>
  │
  ├─ Wait for Phase 1 → report PR → wait for "merge"
  │
  ├─ IN PARALLEL (phase transition):
  │   ├─ Merge Phase 1 PR + kill Phase 1 container
  │   └─ Run Phase 2: implement-issue.sh <repo> <phase2_number>
  │
  ├─ Wait for Phase 2 → report PR → wait for "merge"
  │
  ├─ IN PARALLEL (phase transition):
  │   ├─ Merge Phase 2 PR + kill Phase 2 container
  │   └─ Run Phase 3: implement-issue.sh <repo> <phase3_number>
  │
  ├─ Wait for Phase 3 → report PR → wait for "merge"
  │
  ├─ IN PARALLEL (final cleanup):
  │   ├─ Merge Phase 3 PR
  │   ├─ Kill Phase 3 container
  │   ├─ Orphan container check
  │   └─ Close root issue: gh issue close <root_number> --repo <repo>
  │
  └─ Report: "All phases complete. Root issue closed."
```

### Phase transition detail

When user says "merge" for Phase N:
1. Start these **in parallel**:
   - `gh pr merge <pr_N> --repo <repo> --rebase --delete-branch`
   - `docker kill pipeline-<owner>-<repo>-<phaseN_number> 2>/dev/null || true`
2. Once merge completes, immediately start Phase N+1:
   - `implement-issue.sh <repo> <phaseN+1_number>`
3. Report: "Phase N/total merged. Starting Phase N+1."

Do NOT wait for container kill to finish before starting the next phase. Merge completion is the only gate.

## Progress Reporting

After creating all issues:

```
Feature: Add payment system
Root: https://github.com/<repo>/issues/10

3 phases:
1. Backend — API + DB schema (Issue #11)
2. Frontend — UI screens (Issue #12)
3. Tests — E2E tests (Issue #13)

Starting Phase 1 now.
```

After each phase merges:

```
Phase 1/3 merged (PR #14). Starting Phase 2.
```

After all phases:

```
All 3 phases complete!
- Phase 1: PR #14 (backend) ✓
- Phase 2: PR #15 (frontend) ✓
- Phase 3: PR #16 (tests) ✓
Root issue #10 closed.
Payment feature fully implemented.
```

## Auto-merge Option

If the user says "merge all" or equivalent at the start, merge each PR automatically without waiting for per-phase approval. Still report progress after each merge.

## If a Phase Fails

Stop the sequence. Report the failure with root issue context. Ask user:
- "retry" → run the same phase again
- "skip" → move to next phase
- "cancel" → stop remaining phases

On cancel, report which phases completed and which didn't. Leave root issue open with partial progress visible in the task list.
