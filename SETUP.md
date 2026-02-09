# Claude Pipeline - Setup Guide

Phase 1 + Phase 2 implementation record.

---

## Created Files

```
~/Projects/claude-pipeline/
├── Dockerfile                 # claude-worker container image
├── implement-issue.sh         # Issue → PR automation script
└── SETUP.md                   # This document

~/.openclaw/workspace/skills/
└── auto-implement/
    └── SKILL.md               # Teaches OpenClaw how to use the pipeline

~/.openclaw/exec-approvals.json  # Pre-approved binaries (gh, docker)
```

---

## Modified Config Files

### exec-approvals.json

Pre-approves `gh`, `docker`, and `implement-issue.sh`.
When OpenClaw executes these via the exec tool, no manual approval is required.

```json
{
  "defaults": {
    "security": "allowlist",
    "ask": "on-miss",
    "allowlist": [
      { "pattern": "/opt/homebrew/bin/gh" },
      { "pattern": "/usr/local/bin/docker" },
      { "pattern": "~/Projects/claude-pipeline/implement-issue.sh" }
    ]
  }
}
```

### GitHub Repo Labels (caesar-is-great/elyxs)

| Label | Color | Team Composition |
|-------|-------|------------------|
| `auto-implement` | Green | Default (AI decides) |
| `auto-implement:frontend` | Blue | ui-builder + tester |
| `auto-implement:backend` | Red | api-builder + db-engineer + tester |
| `auto-implement:fullstack` | Purple | fe-builder + be-builder + tester |
| `auto-implement:bugfix` | Yellow | investigator x2 → fixer |

---

## Docker Image: claude-worker

### Contents

```
ubuntu:24.04
├── git, curl, tmux, jq
├── Node.js 22
├── GitHub CLI (gh)
├── Claude Code CLI (@anthropic-ai/claude-code)
├── non-root user: worker (uid 1000)
└── ENV:
    ├── CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1
    └── TERM=xterm-256color
```

### Build Image

```bash
docker build -t claude-worker ~/Projects/claude-pipeline/
```

### Verify Image

```bash
# Check version
docker run --rm claude-worker --version

# Check internal tools
docker run --rm --entrypoint bash claude-worker -c "gh --version && git --version && node --version && tmux -V"
```

---

## Pipeline Flow

```
User: "Add version info to settings screen"
         │
         ▼
implement-issue.sh caesar-is-great/elyxs <issue_number>
         │
         ├─ 1. gh issue view → Fetch issue metadata
         ├─ 2. Select team prompt based on label
         ├─ 3. Clone repo → cached workspace
         ├─ 4. docker run claude-worker
         │     └─ Claude Code (Team Leader)
         │          ├─ Analyze codebase
         │          ├─ TeamCreate → spawn teammates
         │          │   ├─ ui-builder (parallel)
         │          │   └─ tester (parallel)
         │          ├─ Wait for teammates to finish
         │          ├─ git checkout -b feat/issue-N
         │          ├─ git add → commit → push
         │          └─ gh pr create
         ├─ 5. Poll for PR every 30s → stop container when detected
         └─ 6. Send completion notification → cleanup
```

---

## Usage

### Manual Execution

```bash
# Basic usage
DISCORD_CHANNEL_ID=your-channel-id \
  ~/Projects/claude-pipeline/implement-issue.sh caesar-is-great/elyxs 5

# With explicit env vars
ANTHROPIC_API_KEY=sk-ant-... GITHUB_TOKEN=ghp_... DISCORD_CHANNEL_ID=your-channel-id \
  ~/Projects/claude-pipeline/implement-issue.sh caesar-is-great/elyxs 5
```

### Via OpenClaw (Discord/Telegram)

> "Add dark mode to caesar-is-great/elyxs"

OpenClaw's `auto-implement` skill handles issue creation → script execution → PR notification.

---

## Auth Resolution

The script auto-resolves API keys in this order:

```
ANTHROPIC_API_KEY:
  1. $ANTHROPIC_API_KEY env var (if set)
  2. Extracted from ~/.openclaw/agents/main/agent/auth-profiles.json

GITHUB_TOKEN:
  1. $GITHUB_TOKEN env var (if set)
  2. gh auth token (gh CLI auth token)
```

---

## Monitoring & Debugging

### Check Running Containers

```bash
# List running claude-worker containers
docker ps --filter name=pipeline-

# Example output:
# CONTAINER ID  IMAGE          STATUS         NAMES
# a1b2c3d4e5f6  claude-worker  Up 2 minutes   pipeline-owner-repo-7
```

### Attach to Running Container

```bash
# Shell into container (live inspection)
docker exec -it <container_id> bash

# Once inside:
ls -la /workspace/              # Files being worked on
git log --oneline               # Commit history
git diff                        # Current changes
cat ~/.claude/teams/*/config.json  # Team configuration
ls ~/.claude/tasks/             # Task list

# Check tmux sessions (if Agent Teams uses tmux)
tmux list-sessions
tmux attach -t <session_name>   # Attach to observe in real-time
```

### View Container Logs

```bash
# Live logs (implement-issue.sh outputs to foreground)
# → visible in the terminal running the script

# For background runs
docker logs <container_id>
docker logs -f <container_id>   # Follow in real-time
```

### Live Log Viewer (Web)

Each pipeline run starts a local HTTP server:

```bash
# Auto-started by the script, URL included in Discord notification
open http://localhost:19042   # port = 19000 + issue_number
```

### PR Verification

```bash
# View PR diff
gh pr diff <pr_number> --repo owner/repo

# PR details
gh pr view <pr_number> --repo owner/repo

# PR file list
gh pr view <pr_number> --repo owner/repo --json files --jq '.files[].path'

# PR CI status
gh pr checks <pr_number> --repo owner/repo
```

### Background Execution & Monitoring

```bash
# Run in background with log file
~/Projects/claude-pipeline/implement-issue.sh owner/repo 5 \
  > /tmp/pipeline-issue-5.log 2>&1 &

# Follow logs in real-time
tail -f /tmp/pipeline-issue-5.log

# Watch container status (separate terminal)
watch docker ps --filter name=pipeline-
```

### Troubleshooting

```bash
# Container seems stuck
docker ps --filter name=pipeline-        # Check if still running
docker stats <container_id>              # CPU/memory usage

# Force kill (if needed)
docker kill <container_id>

# Rebuild image (after Dockerfile changes)
docker build -t claude-worker ~/Projects/claude-pipeline/

# Clean up all stopped containers
docker container prune -f

# Kill all pipeline containers at once
docker ps --filter name=pipeline- -q | xargs docker kill
```

---

## Test Results

### Phase 1: Single Session (2025-02-09)

| Field | Value |
|-------|-------|
| Issue | #3 - Add README badge for build status |
| PR | #4 |
| Changes | 1 file, +2 lines |
| Mode | Single Claude session |

### Phase 2: Agent Teams (2025-02-09)

| Field | Value |
|-------|-------|
| Issue | #5 - Add app version display in settings screen |
| PR | #6 |
| Changes | 24 files, +504 lines |
| Team | ui-builder + tester (parallel) |
| Label | auto-implement:frontend |

---

## Next Steps (Phase 3+)

- [ ] Phase 3: Validate and optimize label-based team prompt presets
- [ ] Phase 4: AI-driven dynamic team design (repo analysis → auto team composition)
- [ ] Phase 5: GitHub webhook integration (PR notification automation), monitoring dashboard
