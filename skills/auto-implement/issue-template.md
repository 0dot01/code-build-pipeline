# Issue Body Guide

## Why Issue Quality Matters

Claude Code agent teams implement features based **solely on the issue body**. The agents:
- Do NOT see the original user request — only the issue title and body
- Do NOT ask clarifying questions — they interpret the issue literally
- Search the codebase based on file paths and patterns mentioned in the issue
- Split work between team members (frontend/backend) using the issue structure

**A vague issue = agents guessing. A structured issue = agents executing precisely.**

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

## Template Compliance Rules

> **These rules are mandatory. Violating them produces issues that agents cannot implement correctly.**

1. **Use the EXACT section headers** from the template (`## What`, `## Tech Context`, etc.). Do NOT invent your own headers like `## Requirements` or `## Description`.
2. **Fill in ALL REQUIRED sections**. Every section marked `(REQUIRED)` in the template MUST have concrete content.
3. **Replace ALL placeholders** — `<from repos.md>`, `<framework>`, `<relevant paths>` MUST be replaced with actual values from `repos.md`. If `repos.md` has no entry for the target repo, ask the user for tech stack info before creating the issue.
4. **Include specific file paths** — not "the settings page" but `app/(tabs)/settings.tsx`. Agents use these paths to navigate directly to the right files.
5. **Acceptance Criteria must be testable** — each item should describe a verifiable outcome, not a task. Use `- [ ]` checkbox format.

## Pre-Creation Quality Checklist

Before running `gh issue create`, verify:

- [ ] Every template section header is present and filled
- [ ] No `<placeholder>` text remains in the body
- [ ] At least one specific file path is mentioned in Tech Context
- [ ] Existing patterns reference points to a real feature in the repo
- [ ] Acceptance Criteria are end-user-observable outcomes (not implementation tasks)
- [ ] The label matches the actual scope (see edge cases in `labels.md`)

## Anti-Patterns

### BAD: Flat requirements list

```
Add a Daily Review Note feature to the home screen.

## Requirements
- Display 'Today's Review' card section at the top of home screen
- Implement text input field for daily notes (500 character limit)
- Store notes with date-based keys using AsyncStorage
- Show history of last 7 days' notes
```

**Why this fails:**
- No Tech Context → agent wastes time scanning the entire codebase
- No file paths → agent might create files in wrong locations
- No existing patterns → agent invents its own patterns instead of matching the repo's style
- "Requirements" mixes UI, storage, and behavior → hard for team members to split work
- No Acceptance Criteria → agent doesn't know when it's done

### GOOD: Structured template

```
## What
Add a daily review note card to the home screen where users can jot down what they learned.

## Tech Context
- Framework: React Native + Expo (SDK 52)
- Relevant paths: app/(tabs)/index.tsx (home), components/, lib/storage.ts
- Existing patterns: Follow the streak card component in components/StreakCard.tsx
- Storage: AsyncStorage with date-based keys (see lib/storage.ts patterns)
- i18n: All user-facing strings via i18n/locales/*.json

## Details
- Add "Today's Review" card below the hero section on home screen
- TextInput with 500 char limit, auto-save on blur
- Store with key `review_note_YYYY-MM-DD` in AsyncStorage
- Show collapsible history of last 7 days below the input
- Only show for authenticated users (check useAuth hook)
- Dark mode: use theme tokens from constants/Colors.ts

## Acceptance Criteria
- [ ] Review note card visible on home screen for logged-in users
- [ ] Text persists after app restart
- [ ] Last 7 days' notes visible in history section
- [ ] Hidden for guest users
- [ ] Dark mode renders correctly
```

## Title Rules

- English, concise, under 70 characters
- Prefix: `feat:` for features, `fix:` for bugs, `chore:` for maintenance
- Verb after prefix: "add ...", "fix ...", "update ...", "remove ..."
- For multi-issue sub-issues: `feat: [Feature] Phase N: description`
  - Example: `feat: [Payment] Phase 1: API and DB schema`
