# Code Build Pipeline

Automated development pipeline that turns feature requests into pull requests using Claude Code Agent Teams in Docker.

```
Feature request -> GitHub Issue -> Claude Code Agent Teams (Docker) -> PR
```

## How It Works

1. **Orchestrator** (OpenClaw or any LLM assistant) receives a feature request via chat
2. **Scope analysis** determines label and team composition
3. **GitHub Issue** is created with a structured body and acceptance criteria
4. **implement-issue.sh** launches a Docker container running Claude Code with Agent Teams
5. Inside the container, a **Team Leader** spawns specialized teammates (builder, tester, etc.)
6. Teammates implement the feature, write tests, and iterate until all tests pass
7. A **PR** is created automatically. User reviews and merges.

## Architecture

```
Orchestrator (LLM)
  |
  |-- exec: implement-issue.sh <owner/repo> <issue_number>
  |
  v
implement-issue.sh (host)
  |-- Fetches issue from GitHub
  |-- Prepares workspace (cached local clone)
  |-- Launches Docker container
  |
  v
Docker: claude-worker
  |
  |-- Claude Code (Team Leader)
  |     |-- TeamCreate -> teammates
  |     |-- SendMessage -> coordination
  |     |-- Testing Gate -> all tests must pass
  |     |-- gh pr create
  |     |-- TeamDelete
  |
  v
PR created -> User reviews -> Merge
```

## File Structure

```
pipeline/
  implement-issue.sh      # Cached clone + Docker run + status reporting
  Dockerfile              # claude-worker image (Ubuntu + Node + gh + Claude Code)

skills/auto-implement/    # Orchestrator skill files (for OpenClaw or similar)
  SKILL.md                # Main flow: 5-step pipeline
  labels.md               # Scope analysis: size check + label selection
  repos.md                # Known repos and tech stacks
  issue-template.md       # Issue body strategy + template routing
  multi-issue.md          # Large features: root issue + sub-issue orchestration
  reporting.md            # 5 checkpoints + polling + retry flow
  cleanup.md              # Merge + container kill + cancel + status
  errors.md               # 7 error scenarios
  templates/
    frontend.md           # Frontend issue body template
    backend.md            # Backend issue body template
    fullstack.md          # Fullstack issue body template + API contract
    bugfix.md             # Bugfix issue body template + reproduction steps
    generic.md            # Generic issue body template
    sub-issue.md          # Multi-issue phase template + scope boundary
```

## Prerequisites

- **Docker** with `claude-worker` image built
- **GitHub CLI** (`gh`) authenticated
- **Anthropic API key** set as `ANTHROPIC_API_KEY` env var
- **Claude Code** (`@anthropic-ai/claude-code`) npm package

## Setup

### 1. Build the Docker image

```bash
docker build -t claude-worker ./pipeline/
```

### 2. Set environment variables

```bash
export ANTHROPIC_API_KEY="your-api-key"
export GITHUB_TOKEN=$(gh auth token)
```

The script auto-resolves `GITHUB_TOKEN` from `gh auth token` if not set.

### 3. Run manually (without orchestrator)

```bash
# Create a GitHub issue first, then:
./pipeline/implement-issue.sh <owner/repo> <issue_number>
```

### 4. Use with an orchestrator (OpenClaw)

Copy the `skills/auto-implement/` directory to your orchestrator's skill directory. Update the `implement-issue.sh` path in SKILL.md, multi-issue.md, and reporting.md to match your local setup.

You'll also need:
- **exec-approvals** for `gh`, `docker`, and `implement-issue.sh`
- **TOOLS.md** with pipeline paths for your environment
- **Execution rule**: The skill is designed to run autonomously. Once invoked, the orchestrator should execute each step immediately without asking the user for confirmation. Issue creation flows directly into implementation, and independent issues run in parallel automatically.
- **Skill routing** in your agent's `AGENTS.md` (or equivalent config) so the orchestrator knows when to invoke the skill:

```markdown
### Skill Routing (IMPORTANT)

When someone asks you to **build a feature, fix a bug, or make code changes**,
use the `auto-implement` skill. Do NOT try to implement manually or spawn
sub-agents. The auto-implement skill handles everything: issue creation,
Docker containers, Agent Teams, testing, and PR creation.

Flow: Read the skill's SKILL.md → follow the steps → use exec to run implement-issue.sh.

IMPORTANT: Execute each pipeline step immediately without asking for confirmation.
The user already approved by requesting the feature/fix. Do not pause between
issue creation and implementation — proceed automatically.
```

Without explicit routing, the orchestrator may fall back to manual implementation instead of using the pipeline.

## Labels and Team Composition

| Label | Team | Use case |
|-------|------|----------|
| `auto-implement:frontend` | ui-builder + tester | UI changes, screens, components |
| `auto-implement:backend` | api-builder + db-engineer + tester | API, DB, server logic |
| `auto-implement:fullstack` | fe-builder + be-builder + tester | Small features spanning both layers |
| `auto-implement:bugfix` | investigator x2 + tester | Bug fixes with regression testing |
| `auto-implement` | auto-composed + tester | Unclear scope, let AI decide |

Every team **always includes a mandatory tester** who:
1. Reads the issue's Acceptance Criteria
2. Writes a test plan
3. Writes and runs tests (unit, integration, E2E)
4. Reports pass/fail to the team leader

## Testing Gate

PR creation is blocked until **all tests pass**:

```
Implementers build code
  |
  v
Tester runs full test suite
  |
  |- FAIL -> Tester reports to implementer -> Fix -> Re-run
  |           (repeat until all pass)
  |
  |- PASS -> PR created
```

## Multi-Issue (Large Features)

Features spanning multiple layers are split into sequential phases:

```
Root Issue #10: "Add payment system"
  |-- Sub-issue #11: Phase 1 - Backend (API + DB)
  |-- Sub-issue #12: Phase 2 - Frontend (UI)
  |-- Sub-issue #13: Phase 3 - E2E tests
```

- Sub-issues are created **in parallel**
- Sub-issues are executed **sequentially** (Phase 1 must merge before Phase 2 starts)
- Phase transitions run merge + cleanup + next phase start **in parallel**

## Cached Local Clone

The pipeline caches repositories to avoid re-cloning:

```
~/.pipeline/
  repos/<owner>-<repo>/           # Base repo (cloned once, fetched per run)
  worktrees/<owner>-<repo>-<N>/   # Per-issue workspace (local clone, hardlinks)
```

- First run: full network clone (~30s)
- Subsequent runs: `git fetch` + local clone with hardlinks (~2s)

## Status Reporting

The script writes JSON progress to `/tmp/pipeline-<owner>-<repo>-<issue>.status`:

```json
{
  "step": "container",
  "status": "running",
  "message": "Agent Teams working",
  "container": "pipeline-owner-repo-7",
  "repo": "owner/repo",
  "issue": 7,
  "pr_url": "https://github.com/...",
  "pr_number": 8
}
```

## License

MIT
