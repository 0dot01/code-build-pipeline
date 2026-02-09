# Code Build Pipeline

Automated development pipeline that turns feature requests into pull requests using Claude Code Agent Teams in Docker.

```
Feature request -> GitHub Issue -> Claude Code Agent Teams (Docker) -> PR
```

## Architecture

```
Orchestrator (LLM assistant)
  |
  |-- Creates GitHub Issue with label + acceptance criteria
  |-- exec: implement-issue.sh <owner/repo> <issue_number>
  |
  v
implement-issue.sh (host)
  |-- Fetches issue metadata from GitHub
  |-- Prepares workspace (cached local clone)
  |-- Starts live log viewer (HTTP)
  |-- Sends Discord notification: "Pipeline starting"
  |-- Launches Docker container in background
  |-- Polls for PR every 30s (stops container when PR detected)
  |-- Sends Discord notification: success or failure
  |
  v
Docker: claude-worker
  |-- Claude Code (Team Leader)
  |     |-- Reads codebase, creates branch
  |     |-- TeamCreate -> spawns teammates by label
  |     |-- Teammates implement + tester writes tests (parallel)
  |     |-- Testing gate: all tests must pass before PR
  |     |-- git push + gh pr create
  |     |-- TeamDelete
  |
  v
PR created -> User reviews -> Merge
```

## Prerequisites

- **Docker**
- **GitHub CLI** (`gh`) — authenticated via `gh auth login`
- **Node.js** (for Claude Code CLI)
- **Python 3** (for live log viewer)

## Environment Variables

| Variable | Required | Description |
|----------|----------|-------------|
| `ANTHROPIC_API_KEY` | Yes | Anthropic API key. Auto-resolved from `~/.openclaw/agents/main/agent/auth-profiles.json` if not set. |
| `GITHUB_TOKEN` | No | GitHub token. Auto-resolved from `gh auth token` if not set. |
| `DISCORD_CHANNEL_ID` | Yes | Discord channel ID for pipeline notifications. |
| `OPENCLAW_BIN` | No | Path to OpenClaw CLI binary. Default: `/opt/homebrew/bin/openclaw` |

## Setup

### 1. Clone this repo

```bash
git clone https://github.com/caesar-is-great/code-build-pipeline.git
cd code-build-pipeline
```

### 2. Build the Docker image

```bash
docker build -t claude-worker ./pipeline/
```

Verify:
```bash
docker run --rm claude-worker --version
```

### 3. Set environment variables

```bash
export ANTHROPIC_API_KEY="sk-ant-..."
export DISCORD_CHANNEL_ID="your-discord-channel-id"
```

### 4. Run

```bash
# Create a GitHub issue first, then:
./pipeline/implement-issue.sh <owner/repo> <issue_number>
```

## Notifications

The script sends Discord messages at each stage via the OpenClaw CLI (`openclaw message send`). No bot token needed in the script environment — it uses the running OpenClaw gateway.

| Stage | Message |
|-------|---------|
| Start | Pipeline starting for **repo** Issue #N |
| Issue fetched | Issue #N: **title**, label |
| Container running | Agent Teams working — live logs URL |
| Success | PR #N ready! `+additions -deletions`. Review and say **merge**. |
| Failure | Issue #N failed — no PR created. Say **retry** or **cancel**. |

## Live Log Viewer

Each run starts a local HTTP server that streams Docker output with 3-second auto-refresh:

```
http://<local-ip>:<port>
```

Port = `19000 + issue_number` (e.g., issue #42 -> port 19042).

The URL is included in the Discord notification.

## Labels and Team Composition

| Label | Team | Use case |
|-------|------|----------|
| `auto-implement:frontend` | ui-builder + tester | UI changes, screens, components |
| `auto-implement:backend` | api-builder + db-engineer + tester | API, DB, server logic |
| `auto-implement:fullstack` | fe-builder + be-builder + tester | Both layers |
| `auto-implement:bugfix` | investigator x2 + tester | Bug fixes with regression tests |
| `auto-implement` | auto-composed + tester | Unclear scope, AI decides |

Every team always includes a **mandatory tester** who reads acceptance criteria, writes tests, runs the full suite, and blocks PR creation until all tests pass.

## Multi-Issue (Large Features)

Features spanning multiple layers are split into sequential phases:

```
Root Issue #10: "Add payment system"
  |-- Sub-issue #11: Phase 1 - Backend (API + DB)
  |-- Sub-issue #12: Phase 2 - Frontend (UI)
  |-- Sub-issue #13: Phase 3 - E2E tests
```

Sub-issues are created in parallel, executed sequentially.

## File Structure

```
code-build-pipeline/
  pipeline/
    implement-issue.sh        # Main script: clone, docker, poll, notify
    Dockerfile                # claude-worker image (Ubuntu + Node 22 + gh + Claude Code)
  skills/auto-implement/      # Orchestrator skill files
    SKILL.md                  # 5-step pipeline flow
    labels.md                 # Scope analysis + label selection
    repos.md                  # Known repos and tech stacks
    issue-template.md         # Issue body strategy + template routing
    multi-issue.md            # Large feature orchestration
    reporting.md              # 5 notification checkpoints + polling
    cleanup.md                # Merge + cancel + status flows
    errors.md                 # Error scenarios and fixes
    templates/                # Label-specific issue body templates
      frontend.md
      backend.md
      fullstack.md
      bugfix.md
      generic.md
      sub-issue.md
```

## Monitoring

```bash
# List running pipeline containers
docker ps --filter name=pipeline-

# Shell into a running container
docker exec -it pipeline-owner-repo-7 bash

# Inside the container:
ls /workspace/                       # Working files
git log --oneline                    # Commits
tmux list-sessions                   # Agent Teams sessions

# View container logs
docker logs -f pipeline-owner-repo-7

# Check status file
cat /tmp/pipeline-owner-repo-7.status
```

## Troubleshooting

```bash
# Force kill a stuck container
docker kill pipeline-owner-repo-7

# Kill all pipeline containers
docker ps --filter name=pipeline- -q | xargs docker kill

# Rebuild image after Dockerfile changes
docker build -t claude-worker ./pipeline/

# Clean up stopped containers
docker container prune -f
```

## Using with an Orchestrator

Copy `skills/auto-implement/` to your orchestrator's skill directory. You'll need:

- **exec-approvals** for `gh`, `docker`, and `implement-issue.sh`
- **Skill routing** so the orchestrator knows to use the pipeline for build/fix requests
- **Autonomous execution**: the skill runs each step without asking for confirmation

See `skills/auto-implement/SKILL.md` for the full 5-step flow.

## License

MIT
