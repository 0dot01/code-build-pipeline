#!/usr/bin/env bash
set -euo pipefail

# Usage: ./implement-issue.sh <owner/repo> <issue_number>
# Runs claude-worker container with Agent Teams to implement a GitHub issue.
# Writes progress to /tmp/pipeline-<container-name>.status (JSON)
# Repo cache: ~/.pipeline/repos/<repo> (cloned once, fetched per run)
# Workspaces: ~/.pipeline/worktrees/<repo>-<issue> (local clone with hardlinks)

REPO="${1:?Usage: implement-issue.sh <owner/repo> <issue_number>}"
ISSUE_NUMBER="${2:?Usage: implement-issue.sh <owner/repo> <issue_number>}"

# Naming and paths
REPO_NAME=$(echo "$REPO" | tr '/' '-')
CONTAINER_NAME="pipeline-${REPO_NAME}-${ISSUE_NUMBER}"
STATUS_FILE="/tmp/${CONTAINER_NAME}.status"
ISSUE_URL="https://github.com/${REPO}/issues/${ISSUE_NUMBER}"

# Cached repo: network clone once, local clone per issue (hardlinks for .git objects)
PIPELINE_DIR="$HOME/.pipeline"
REPOS_DIR="${PIPELINE_DIR}/repos"
WORKTREES_DIR="${PIPELINE_DIR}/worktrees"
BASE_REPO="${REPOS_DIR}/${REPO_NAME}"
WORKDIR="${WORKTREES_DIR}/${REPO_NAME}-${ISSUE_NUMBER}"

# Write structured status to file (overwrite = always latest state)
write_status() {
  local step="$1" status="$2" message="$3"
  shift 3
  local extra=""
  while [ $# -gt 0 ]; do
    extra="${extra},\"$1\":\"$2\""
    shift 2
  done
  echo "{\"step\":\"${step}\",\"status\":\"${status}\",\"message\":\"${message}\",\"container\":\"${CONTAINER_NAME}\",\"repo\":\"${REPO}\",\"issue\":${ISSUE_NUMBER},\"issue_url\":\"${ISSUE_URL}\",\"ts\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"${extra}}" > "$STATUS_FILE"
}

# --- Notifications (OpenClaw CLI — no token needed, uses running gateway) ---
DISCORD_CHANNEL_ID="${DISCORD_CHANNEL_ID:?Set DISCORD_CHANNEL_ID env var}"
OPENCLAW_BIN="${OPENCLAW_BIN:-/opt/homebrew/bin/openclaw}"

notify() {
  local msg="$1"
  echo "==> [notify] Sending: ${msg:0:80}..."
  "$OPENCLAW_BIN" message send \
    --channel discord \
    --target "$DISCORD_CHANNEL_ID" \
    --message "$msg" 2>&1 || echo "==> [notify] FAILED: $?"
  echo "==> [notify] Done."
}

# --- Live Log Viewer ---
LOG_FILE="/tmp/${CONTAINER_NAME}.log"
LOG_PORT=$((19000 + ISSUE_NUMBER))
LOG_VIEWER_PID=""
LOCAL_IP=$(ipconfig getifaddr en0 2>/dev/null || echo "localhost")
LOG_URL="http://${LOCAL_IP}:${LOG_PORT}"

start_log_viewer() {
  local viewer_script="/tmp/${CONTAINER_NAME}-viewer.py"
  cat > "$viewer_script" << 'PYEOF'
import http.server, sys, html, os

LOG_FILE = sys.argv[1]
CONTAINER = os.environ.get("CONTAINER_NAME", "pipeline")

class Handler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        try:
            content = open(LOG_FILE).read()
        except FileNotFoundError:
            content = "Waiting for output..."
        escaped = html.escape(content)
        page = f"""<!DOCTYPE html><html><head><meta charset="utf-8">
<meta http-equiv="refresh" content="3">
<title>{CONTAINER}</title>
<style>
body {{ background:#0d1117; color:#c9d1d9; font-family:'SF Mono','Menlo',monospace; font-size:13px; padding:20px; margin:0; }}
pre {{ white-space:pre-wrap; word-wrap:break-word; }}
.hdr {{ color:#58a6ff; border-bottom:1px solid #30363d; padding-bottom:10px; margin-bottom:10px; }}
</style></head>
<body><div class="hdr">{CONTAINER} — auto-refresh 3s</div>
<pre>{escaped}</pre>
<script>window.scrollTo(0,document.body.scrollHeight);</script>
</body></html>"""
        self.send_response(200)
        self.send_header("Content-Type", "text/html; charset=utf-8")
        self.end_headers()
        self.wfile.write(page.encode())
    def log_message(self, *a): pass

http.server.HTTPServer(("0.0.0.0", int(sys.argv[2])), Handler).serve_forever()
PYEOF
  CONTAINER_NAME="$CONTAINER_NAME" python3 "$viewer_script" "$LOG_FILE" "$LOG_PORT" &
  LOG_VIEWER_PID=$!
}

stop_log_viewer() {
  [ -n "$LOG_VIEWER_PID" ] && kill "$LOG_VIEWER_PID" 2>/dev/null || true
  rm -f "/tmp/${CONTAINER_NAME}-viewer.py"
}

write_status "init" "running" "Pipeline starting"
notify "🔧 Pipeline starting for **${REPO}** Issue #${ISSUE_NUMBER}"

# Resolve API keys from env, OpenClaw agent config, or gh auth
if [ -z "${ANTHROPIC_API_KEY:-}" ]; then
  ANTHROPIC_API_KEY=$(python3 -c "
import json
with open('$HOME/.openclaw/agents/main/agent/auth-profiles.json') as f:
    d = json.load(f)
print(d['profiles']['anthropic:default']['key'])
" 2>/dev/null || true)
fi
if [ -z "${GITHUB_TOKEN:-}" ]; then
  GITHUB_TOKEN=$(gh auth token 2>/dev/null || true)
fi

if [ -z "$ANTHROPIC_API_KEY" ]; then
  write_status "init" "failed" "ANTHROPIC_API_KEY not found"
  exit 1
fi
if [ -z "$GITHUB_TOKEN" ]; then
  write_status "init" "failed" "GITHUB_TOKEN not found"
  exit 1
fi

# Kill any existing container for the same issue (prevent duplicates)
if docker ps -q --filter "name=${CONTAINER_NAME}" | grep -q .; then
  echo "==> Killing existing container ${CONTAINER_NAME}..."
  docker kill "$CONTAINER_NAME" 2>/dev/null || true
  docker rm "$CONTAINER_NAME" 2>/dev/null || true
fi

write_status "fetch" "running" "Fetching issue #${ISSUE_NUMBER}"

echo "==> Fetching issue #${ISSUE_NUMBER} from ${REPO}..."
ISSUE_JSON=$(gh issue view "$ISSUE_NUMBER" --repo "$REPO" --json title,body,labels 2>&1)
ISSUE_TITLE=$(echo "$ISSUE_JSON" | jq -r '.title')
ISSUE_BODY=$(echo "$ISSUE_JSON" | jq -r '.body // "No description"')
ISSUE_LABELS=$(echo "$ISSUE_JSON" | jq -r '[.labels[].name] | join(",")')

echo "==> Issue: #${ISSUE_NUMBER} - ${ISSUE_TITLE}"
echo "==> Labels: ${ISSUE_LABELS}"
notify "📋 Issue #${ISSUE_NUMBER}: **${ISSUE_TITLE}**
Label: \`${ISSUE_LABELS}\`
${ISSUE_URL}"

write_status "clone" "running" "Preparing workspace for ${REPO}"

mkdir -p "$REPOS_DIR" "$WORKTREES_DIR"

# Base repo: network clone once, fetch to update
if [ ! -d "$BASE_REPO/.git" ]; then
  echo "==> First time: cloning ${REPO} into cache..."
  gh repo clone "$REPO" "$BASE_REPO"
else
  echo "==> Updating cached repo..."
  git -C "$BASE_REPO" remote set-url origin "https://x-access-token:${GITHUB_TOKEN}@github.com/${REPO}.git"
  git -C "$BASE_REPO" fetch origin --prune
  git -C "$BASE_REPO" remote set-url origin "https://github.com/${REPO}.git"
fi

# Per-issue workspace: local clone with hardlinks (~2 seconds)
rm -rf "$WORKDIR"
echo "==> Creating workspace from cache..."
git clone "$BASE_REPO" "$WORKDIR"

# Point remote to GitHub (local clone defaults to base repo path)
git -C "$WORKDIR" remote set-url origin "https://x-access-token:${GITHUB_TOKEN}@github.com/${REPO}.git"

# Fix ownership so container user (worker, uid 1000) can write
chmod -R 777 "$WORKDIR"

# Cleanup on exit (trap handles: normal exit, error, SIGINT, SIGTERM)
cleanup() {
  echo "==> Cleaning up..."
  stop_log_viewer
  docker kill "$CONTAINER_NAME" 2>/dev/null || true
  docker rm "$CONTAINER_NAME" 2>/dev/null || true
  rm -rf "$WORKDIR"
  rm -f "$LOG_FILE"
  echo "==> Cleanup done."
}
trap cleanup EXIT

# Branch name from issue number
BRANCH="feat/issue-${ISSUE_NUMBER}"

# Select team prompt based on labels
select_team_prompt() {
  local labels="$1"
  case "$labels" in
    *auto-implement:frontend*)
      cat <<'TEAM'
Create an agent team for this frontend task:
- ui-builder: Implement components, pages, and styles
- tester: (MANDATORY) Read the Acceptance Criteria. Write a test plan listing what to verify. Write unit tests (component rendering, user interactions, state changes) and integration tests. Run ALL tests. Report pass/fail with details.
Use Sonnet for all teammates. ui-builder and tester work in parallel (tester writes test specs while ui-builder implements).
TEAM
      ;;
    *auto-implement:backend*)
      cat <<'TEAM'
Create an agent team for this backend task:
- api-builder: Implement endpoints and business logic
- db-engineer: Handle schema changes and migrations
- tester: (MANDATORY) Read the Acceptance Criteria. Write a test plan listing what to verify. Write API tests (endpoint responses, error cases, auth, edge cases) and integration tests. Run ALL tests. Report pass/fail with details.
Use Sonnet for all teammates. Implementers and tester work in parallel (tester writes test specs while implementers build).
TEAM
      ;;
    *auto-implement:fullstack*)
      cat <<'TEAM'
Create an agent team for this fullstack task:
- fe-builder: Implement frontend components, pages, and UI
- be-builder: Implement backend API endpoints and business logic
- tester: (MANDATORY) Read the Acceptance Criteria. Write a test plan listing what to verify. Write E2E tests covering the full user flow, plus unit tests for each layer. Run ALL tests. Report pass/fail with details.
Use Sonnet for all teammates. fe-builder and be-builder work in parallel, tester writes test specs in parallel, then tester validates after implementation.
TEAM
      ;;
    *auto-implement:bugfix*)
      cat <<'TEAM'
Create an agent team to debug and fix this issue:
- investigator-1: Analyze the bug from hypothesis A
- investigator-2: Analyze the bug from hypothesis B
- tester: (MANDATORY) Write a regression test that REPRODUCES the bug BEFORE the fix. After investigators identify the root cause, spawn a fixer. After fix is applied, verify: (1) regression test now passes, (2) all existing tests still pass. Report pass/fail with details.
Have investigators discuss findings via SendMessage. Use Sonnet for all teammates.
TEAM
      ;;
    *)
      cat <<'TEAM'
Analyze this issue and decide the best team composition. Create 2-4 teammates based on the scope. Assign non-overlapping file responsibilities to avoid conflicts.
IMPORTANT: You MUST always include a tester teammate. The tester reads the Acceptance Criteria, writes a test plan, writes tests (unit/integration/E2E as appropriate), runs ALL tests, and reports pass/fail. Use Sonnet for all teammates.
TEAM
      ;;
  esac
}

TEAM_PROMPT=$(select_team_prompt "$ISSUE_LABELS")

PROMPT="You are a team leader implementing GitHub Issue #${ISSUE_NUMBER} for the repository ${REPO}.

## Issue Title
${ISSUE_TITLE}

## Issue Description
${ISSUE_BODY}

## Team Instructions
${TEAM_PROMPT}

## Workflow
1. Read the codebase to understand the project structure, tech stack, conventions, and existing test setup.
2. Create a new branch: git checkout -b ${BRANCH}
3. Create the agent team. The tester starts writing test specs from Acceptance Criteria immediately (in parallel with implementers).
4. Ensure teammates work on SEPARATE files to avoid merge conflicts.
5. Monitor progress via SendMessage. When implementers finish, notify the tester to finalize and run tests.
6. TESTING GATE (mandatory, do NOT skip):
   a. Tester runs the full test suite (new tests + existing tests).
   b. If ANY test fails:
      - Tester sends failure details to the relevant implementer via SendMessage.
      - Implementer fixes the code.
      - Tester re-runs ALL tests.
      - Repeat until ALL tests pass.
   c. Do NOT proceed to step 7 until all tests pass.
7. After all tests pass:
   a. Review the combined changes for consistency.
   b. Stage and commit all changes with a descriptive message referencing Issue #${ISSUE_NUMBER}.
   c. Push the branch: git push origin ${BRANCH}
   d. Create a PR: gh pr create --repo ${REPO} --base main --title \"${ISSUE_TITLE}\" --body \"Closes #${ISSUE_NUMBER}\" --head ${BRANCH}
8. Shut down all teammates and delete the team.

## Rules
- Do NOT ask for confirmation. Execute all steps autonomously.
- Keep each teammate focused on their assigned scope.
- If a teammate encounters an error, help them resolve it via SendMessage.
- NEVER create a PR if tests are failing. The testing gate is mandatory.
- The tester teammate is required in every team, regardless of task type."

write_status "container" "running" "Agent Teams working" "label" "$ISSUE_LABELS"

# Start live log viewer
> "$LOG_FILE"
start_log_viewer
notify "⚙️ Agent Teams working on Issue #${ISSUE_NUMBER} — may take 5-15 min
Container: \`${CONTAINER_NAME}\`
Live logs: ${LOG_URL}"

echo "==> Starting container ${CONTAINER_NAME} (Agent Teams mode)..."
echo "==> Live logs: ${LOG_URL}"

# Run docker in background, poll for PR completion
set +e
docker run --rm -t \
  --name "$CONTAINER_NAME" \
  -v "${WORKDIR}:/workspace" \
  -w /workspace \
  -e ANTHROPIC_API_KEY="$ANTHROPIC_API_KEY" \
  -e GITHUB_TOKEN="$GITHUB_TOKEN" \
  -e GH_TOKEN="$GITHUB_TOKEN" \
  -e HOME=/home/worker \
  -e CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1 \
  -e TERM=xterm-256color \
  claude-worker \
  -p "$PROMPT" \
  --dangerously-skip-permissions \
  --output-format text 2>&1 | tee "$LOG_FILE" &
DOCKER_PID=$!

# Monitor: wait for docker to finish, or detect PR created and force stop
POLL_INTERVAL=30
while kill -0 "$DOCKER_PID" 2>/dev/null; do
  sleep "$POLL_INTERVAL"

  # Check if PR was already created (work is done, container just hasn't exited)
  if gh pr list --repo "$REPO" --head "$BRANCH" --json number --jq '.[0].number' 2>/dev/null | grep -q .; then
    echo "==> PR detected! Stopping container (work complete, container hung)..."
    docker stop "$CONTAINER_NAME" --time 10 2>/dev/null || true
    break
  fi
done

wait "$DOCKER_PID" 2>/dev/null
EXIT_CODE=$?
echo "==> Container exited with code ${EXIT_CODE}"

# Check for PR (the real success indicator — exit code is unreliable due to force-stop)
PR_JSON=$(gh pr list --repo "$REPO" --head "$BRANCH" --json number,url,title,additions,deletions --jq '.[0] // empty' 2>/dev/null || echo "")
PR_URL=$(echo "$PR_JSON" | jq -r '.url // empty' 2>/dev/null || echo "")
PR_NUMBER=$(echo "$PR_JSON" | jq -r '.number // empty' 2>/dev/null || echo "")

if [ -n "$PR_URL" ] && [ "$PR_URL" != "null" ]; then
  PR_ADDITIONS=$(echo "$PR_JSON" | jq -r '.additions // 0' 2>/dev/null || echo "0")
  PR_DELETIONS=$(echo "$PR_JSON" | jq -r '.deletions // 0' 2>/dev/null || echo "0")
  write_status "done" "success" "PR #${PR_NUMBER} created" "pr_url" "$PR_URL" "pr_number" "$PR_NUMBER" "additions" "$PR_ADDITIONS" "deletions" "$PR_DELETIONS"
  notify "✅ PR #${PR_NUMBER} ready for Issue #${ISSUE_NUMBER}!
${PR_URL}
\`+${PR_ADDITIONS} -${PR_DELETIONS}\`
Review and say **merge** when ready."
  EXIT_CODE=0
else
  write_status "done" "failed" "No PR found (exit code ${EXIT_CODE})" "exit_code" "$EXIT_CODE"
  notify "❌ Issue #${ISSUE_NUMBER} failed — no PR created.
${ISSUE_URL}
Say **retry** or **cancel**."
fi

# Stop log viewer before exiting (cleanup trap also handles this, belt-and-suspenders)
stop_log_viewer
exit $EXIT_CODE
