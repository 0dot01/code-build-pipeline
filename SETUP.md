# Claude Pipeline - Setup Guide

Phase 1 + Phase 2 구현 완료 기록.

---

## 만들어진 파일들

```
~/Projects/claude-pipeline/
├── Dockerfile                 # claude-worker 컨테이너 이미지
├── implement-issue.sh         # 이슈 → PR 자동화 스크립트
└── SETUP.md                   # 이 문서

~/.openclaw/workspace/skills/
└── auto-implement/
    └── SKILL.md               # OpenClaw에게 파이프라인 사용법 교육

~/.openclaw/exec-approvals.json  # gh, docker 사전 승인 설정
```

---

## 변경된 설정 파일

### exec-approvals.json

`gh`, `docker`, `implement-issue.sh` 를 사전 승인 등록.
OpenClaw이 exec 도구로 이 명령들을 실행할 때 수동 승인 없이 바로 실행됨.

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

### GitHub 레포 라벨 (caesar-is-great/elyxs)

| 라벨 | 색상 | 팀 구성 |
|------|------|---------|
| `auto-implement` | 초록 | 기본 (AI 자동 판단) |
| `auto-implement:frontend` | 파랑 | ui-builder + tester |
| `auto-implement:backend` | 빨강 | api-builder + db-engineer + tester |
| `auto-implement:fullstack` | 보라 | fe-builder + be-builder + tester |
| `auto-implement:bugfix` | 노랑 | investigator x2 → fixer |

---

## Docker 이미지: claude-worker

### 구성

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

### 이미지 빌드

```bash
docker build -t claude-worker ~/Projects/claude-pipeline/
```

### 이미지 확인

```bash
# 버전 확인
docker run --rm claude-worker --version

# 내부 도구 확인
docker run --rm --entrypoint bash claude-worker -c "gh --version && git --version && node --version && tmux -V"
```

---

## 파이프라인 흐름

```
사람: "설정 화면에 버전 정보 추가해줘"
         │
         ▼
implement-issue.sh caesar-is-great/elyxs <issue_number>
         │
         ├─ 1. gh issue view → 이슈 정보 가져오기
         ├─ 2. 라벨 기반 팀 프롬프트 선택
         ├─ 3. 레포 클론 → /tmp 임시 디렉토리
         ├─ 4. docker run claude-worker
         │     └─ Claude Code (리더)
         │          ├─ 코드 분석
         │          ├─ TeamCreate → 팀원 스폰
         │          │   ├─ ui-builder (병렬)
         │          │   └─ tester (병렬)
         │          ├─ 팀원 완료 대기
         │          ├─ git checkout -b feat/issue-N
         │          ├─ git add → commit → push
         │          └─ gh pr create
         ├─ 5. 컨테이너 종료 (--rm)
         └─ 6. 임시 디렉토리 정리
```

---

## 사용법

### 수동 실행

```bash
# 기본 사용
~/Projects/claude-pipeline/implement-issue.sh caesar-is-great/elyxs 5

# 환경변수를 직접 지정하고 싶을 때
ANTHROPIC_API_KEY=sk-ant-... GITHUB_TOKEN=ghp_... \
  ~/Projects/claude-pipeline/implement-issue.sh caesar-is-great/elyxs 5
```

### OpenClaw 에서 (Discord/Telegram)

> "caesar-is-great/elyxs에 다크모드 추가해줘"

OpenClaw의 `auto-implement` 스킬이 이슈 생성 → implement-issue.sh 실행 → PR 알림까지 처리.

---

## 인증 흐름

스크립트가 API 키를 자동으로 찾는 순서:

```
ANTHROPIC_API_KEY:
  1. 환경변수 $ANTHROPIC_API_KEY (있으면 사용)
  2. ~/.openclaw/agents/main/agent/auth-profiles.json 에서 추출

GITHUB_TOKEN:
  1. 환경변수 $GITHUB_TOKEN (있으면 사용)
  2. gh auth token (gh CLI 인증 토큰)
```

---

## 모니터링 & 디버깅

### 실행 중인 컨테이너 확인

```bash
# 현재 돌고 있는 claude-worker 확인
docker ps --filter ancestor=claude-worker

# 출력 예시:
# CONTAINER ID  IMAGE          STATUS         NAMES
# a1b2c3d4e5f6  claude-worker  Up 2 minutes   quirky_turing
```

### 실행 중인 컨테이너에 접속

```bash
# 컨테이너 안에 셸로 접속 (실시간 확인)
docker exec -it <container_id> bash

# 접속 후 확인할 수 있는 것들:
ls -la /workspace/              # 작업 중인 코드 파일들
git log --oneline               # 커밋 내역
git diff                        # 현재 변경사항
cat ~/.claude/teams/*/config.json  # 팀 구성 확인
ls ~/.claude/tasks/             # 작업 목록 확인

# tmux 세션 확인 (Agent Teams가 tmux 사용 시)
tmux list-sessions
tmux attach -t <session_name>   # 특정 세션에 붙어서 실시간 관찰
```

### 컨테이너 로그 보기

```bash
# 실시간 로그 (implement-issue.sh가 포그라운드로 출력)
# → 스크립트 실행 터미널에서 바로 보임

# 백그라운드 실행 시 로그 확인
docker logs <container_id>
docker logs -f <container_id>   # 실시간 follow
```

### PR 검증

```bash
# PR diff 확인 (코드 변경 내역)
gh pr diff <pr_number> --repo caesar-is-great/elyxs

# PR 상세 정보
gh pr view <pr_number> --repo caesar-is-great/elyxs

# PR 파일 목록
gh pr view <pr_number> --repo caesar-is-great/elyxs --json files --jq '.files[].path'

# PR CI 상태
gh pr checks <pr_number> --repo caesar-is-great/elyxs
```

### 백그라운드 실행 & 모니터링

```bash
# 백그라운드로 실행하고 로그 파일로 출력
~/Projects/claude-pipeline/implement-issue.sh caesar-is-great/elyxs 5 \
  > /tmp/pipeline-issue-5.log 2>&1 &

# 실시간 로그 확인
tail -f /tmp/pipeline-issue-5.log

# 컨테이너 상태 확인 (별도 터미널)
watch docker ps --filter ancestor=claude-worker
```

### 문제 해결

```bash
# 컨테이너가 멈춘 것 같을 때
docker ps --filter ancestor=claude-worker   # 아직 살아있는지 확인
docker stats <container_id>                 # CPU/메모리 사용량

# 강제 종료 (필요 시)
docker kill <container_id>

# 이미지 재빌드 (Dockerfile 변경 후)
docker build -t claude-worker ~/Projects/claude-pipeline/

# 전체 정리 (모든 종료된 컨테이너 삭제)
docker container prune -f
```

---

## 테스트 결과

### Phase 1: 단일 세션 (2025-02-09)

| 항목 | 값 |
|------|-----|
| Issue | #3 - Add README badge for build status |
| PR | #4 |
| 변경 | 1 file, +2 lines |
| 모드 | 단일 Claude 세션 |

### Phase 2: Agent Teams (2025-02-09)

| 항목 | 값 |
|------|-----|
| Issue | #5 - Add app version display in settings screen |
| PR | #6 |
| 변경 | 24 files, +504 lines |
| 팀 | ui-builder + tester (병렬) |
| 라벨 | auto-implement:frontend |

---

## 다음 단계 (Phase 3+)

- [ ] Phase 3: 라벨별 프리셋 팀 프롬프트 검증 및 최적화
- [ ] Phase 4: AI 동적 팀 설계 (레포 분석 → 자동 팀 구성)
- [ ] Phase 5: GitHub webhook 연동 (PR 알림 자동화), 모니터링 대시보드
