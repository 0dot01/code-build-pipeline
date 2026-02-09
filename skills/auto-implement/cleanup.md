# Merge + Cleanup + Cancel + Status

## After merge

Triggered by: "merge", "LGTM", or equivalent.

Run steps 1-3 **in parallel** (they are independent):

### 1. Merge PR

```bash
gh pr merge <pr_number> --repo <owner/repo> --rebase --delete-branch
```

### 2. Kill the issue's container

```bash
docker kill pipeline-<owner>-<repo>-<issue_number> 2>/dev/null || true
docker rm pipeline-<owner>-<repo>-<issue_number> 2>/dev/null || true
```

### 3. Check for orphan containers

```bash
docker ps --filter name=pipeline- --format "{{.Names}} {{.Status}}"
```

No output = clean. If output exists, report to user and ask whether to kill.

### 4. Report (after 1-3 all complete)

"Merged! Issue #N closed. Containers cleaned up."

---

## Cancel / Abort

Triggered by: "cancel", "stop", "abort", or equivalent.

### Kill specific issue container

```bash
docker kill pipeline-<owner>-<repo>-<issue_number> 2>/dev/null || true
```

### Kill all pipeline containers

```bash
docker ps --filter name=pipeline- -q | xargs -r docker kill
```

### After cancel, report and ask about the issue

"Pipeline stopped. Container killed. Issue #N is still open. Close it?"

If yes:
```bash
gh issue close <issue_number> --repo <owner/repo>
```

---

## Status check

Triggered by: "what's running?", "status", or equivalent.

```bash
docker ps --filter name=pipeline- --format "table {{.Names}}\t{{.Status}}"
```

Running: report container name + uptime, ask wait or kill.
Nothing: "No pipelines running."
