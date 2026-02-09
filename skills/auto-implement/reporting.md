# Reporting Guide

## Status File

The pipeline writes progress to `/tmp/pipeline-<owner>-<repo>-<issue_number>.status` (JSON).

Example: `/tmp/pipeline-owner-repo-7.status`

Read this file to get current state. It is overwritten at each milestone (always shows latest).

### Status file fields

```json
{
  "step": "container",
  "status": "running",
  "message": "Agent Teams working",
  "container": "pipeline-owner-repo-7",
  "repo": "owner/repo",
  "issue": 7,
  "issue_url": "https://github.com/owner/repo/issues/7",
  "ts": "2026-02-09T12:00:00Z",
  "label": "auto-implement:frontend"
}
```

On success, additional fields appear: `pr_url`, `pr_number`, `additions`, `deletions`.
On failure: `exit_code`.

---

## Report Checkpoints

Send a message to the user at each of these moments. Do NOT skip any.

### Checkpoint 1: Issue created (after Step 2)

```
Issue #{number} created: {issue_url}
Label: {label}
Starting implementation — this may take 5-15 minutes.
```

### Checkpoint 2: Pipeline running (after Step 3 starts)

Read the status file to confirm the container started:
```bash
cat /tmp/pipeline-<owner>-<repo>-<issue_number>.status
```

If step=container and status=running, no extra message needed (Checkpoint 1 already informed the user).

If the container has been running >10 minutes, send a progress update:
```
Still working on Issue #{number}. Container running for {minutes} minutes.
```

### Checkpoint 3: Success (status=success)

Read the status file. Extract pr_url, pr_number, additions, deletions.

```
PR #{pr_number} is ready!
{pr_url}
+{additions} -{deletions}
Review and say "merge" when ready.
```

### Checkpoint 4: Failure (status=failed)

Read the status file. Extract message and exit_code.

```
Implementation failed for Issue #{number}.
Error: {message}
Retry? (I can run it again, or you can adjust the issue and retry.)
```

Wait for user response:
- "retry" / "again" -> run implement-issue.sh again with same args
- "cancel" / "no" -> read `cleanup.md` for cancel flow
- "edit" -> let user modify the issue, then retry

### Checkpoint 5: After merge (Step 5)

```
Merged! Issue #{number} closed. Branch deleted. Containers cleaned up.
```

---

## Polling Strategy

After starting implement-issue.sh in background:

1. Wait ~30 seconds, then read the status file once to confirm it started.
2. Do NOT poll in a tight loop. Check only when:
   - The user asks for status
   - A heartbeat fires
   - The background exec process completes (OpenClaw receives the completion event)
3. When the exec process completes, immediately read the status file and send Checkpoint 3 or 4.

---

## Error Retry Flow

On failure:
1. Send Checkpoint 4 message
2. Wait for user response
3. If retry:
   - The script auto-kills any existing container for the same issue
   - Just run the same command again:
     ```bash
     implement-issue.sh <owner/repo> <issue_number>
     ```
4. If cancel: follow `cleanup.md`
