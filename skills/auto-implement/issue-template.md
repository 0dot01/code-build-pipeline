# Issue Body Guide

Claude Code implements based solely on the issue body. More detail = better results.
OpenClaw must transform a short user request into a rich, actionable issue body.

## Body Generation Strategy

1. **Read `repos.md`** (already loaded from Step 1) — get tech stack, structure, conventions.
2. **Infer specifics** — based on the tech stack, fill in frameworks, file paths, and patterns. Don't ask the user things you can infer.
3. **Ask only when ambiguous** — if the request is genuinely unclear (e.g., "improve performance" — where?), ask one focused question.

### What to infer (examples)

Use the tech stack from `repos.md` to fill in framework-specific details:

| User says | What to infer from tech stack |
|-----------|-------------------------------|
| "Add settings screen" | Router type → file path, existing theme/components |
| "Add push notifications" | Backend service, notification API, permission handling |
| "Fix login crash" | Auth module path, error boundaries, auth flow |
| "Add dark mode" | Theme hook, storage for persistence, ThemeProvider pattern |

## Pick Template by Label

Read **one** template file based on the label chosen in Step 1:

| Label | Read this file |
|-------|---------------|
| `auto-implement:frontend` | `templates/frontend.md` |
| `auto-implement:backend` | `templates/backend.md` |
| `auto-implement:fullstack` | `templates/fullstack.md` |
| `auto-implement:bugfix` | `templates/bugfix.md` |
| `auto-implement` | `templates/generic.md` |

For multi-issue sub-issues (from `multi-issue.md`), read `templates/sub-issue.md` instead.

## Title Rules

- English, concise, under 70 characters
- Verb prefix: "Add ...", "Fix ...", "Update ...", "Remove ..."
- For multi-issue sub-issues: "[Feature] Phase N: description"
  - Example: "[Payment] Phase 1: API and DB schema"
