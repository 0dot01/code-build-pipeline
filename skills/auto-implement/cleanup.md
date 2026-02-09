# Merge + Cleanup + Cancel + Status

## After merge

Triggered by: "merge", "LGTM", or equivalent.

Note: The container is already stopped and cleaned up by `implement-issue.sh` (PR polling + cleanup trap). No docker commands needed here.

### 1. Merge PR

```bash
gh pr merge <pr_number> --repo <owner/repo> --rebase --delete-branch
```

### 2. Report

"Merged! Issue #N closed. Branch deleted."

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
