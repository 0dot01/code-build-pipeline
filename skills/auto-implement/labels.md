# Label Selection Guide

## Step 1: Check size first

Is this a **large feature** requiring 2+ layers (backend + frontend + tests + deploy)?

- YES → read `multi-issue.md` and split into multiple issues. Each issue gets its own label.
- NO → pick one label below.

### Large feature signals

- Needs new API endpoints AND new UI screens
- Involves DB schema changes AND frontend consuming them
- User explicitly describes a multi-part feature ("add payment system", "add social login with UI")
- Estimated scope: 10+ files across multiple directories

### NOT large (single issue is fine)

- Only one layer affected (just UI, just API, just a fix)
- Small fullstack change (e.g., add one field end-to-end)
- Under 10 files estimated

## Step 2: Pick label

| Label | When to use | Team composition |
|-------|------------|------------------|
| `auto-implement:frontend` | UI changes, new screens, styles, components, themes, animations | ui-builder + tester |
| `auto-implement:backend` | API, DB, server logic, schema, migrations, auth logic | api-builder + db-engineer + tester |
| `auto-implement:fullstack` | Small features requiring both frontend and backend | fe-builder + be-builder + tester |
| `auto-implement:bugfix` | Bug fixes, crash fixes, error resolution | investigator x2 -> fixer |
| `auto-implement` | Unclear scope, simple tasks -> let AI decide | auto (2-4 members) |

## Edge Cases — Common Misclassifications

These are frequently misclassified. Pay attention:

| Feature | Looks like... | Actually is... | Why |
|---------|--------------|----------------|-----|
| "Add daily notes with AsyncStorage" | `fullstack` | `frontend` | AsyncStorage is client-side only, no backend API needed |
| "Add local settings/preferences" | `fullstack` | `frontend` | Client-side storage, no server involved |
| "Add loading spinner to login" | `frontend` | `fullstack` | Spinner needs API response state from backend |
| "Cache API responses locally" | `backend` | `frontend` | Caching happens on client side (React Query, AsyncStorage) |
| "Add form validation" | `frontend` | depends | Frontend-only if client validation; fullstack if server validation too |

**Rule of thumb**: If data never leaves the device (AsyncStorage, SecureStore, local state), it's `frontend`. Only use `fullstack` when both a server API change AND a UI change are needed.

## Examples

### Single issue

- "Add dark mode" -> `frontend`
- "Show version in settings" -> `frontend`
- "Add daily review notes (stored locally)" -> `frontend` (AsyncStorage = client-side)
- "Add local preferences/settings" -> `frontend`
- "API responses are slow" -> `backend`
- "Login is broken" -> `bugfix`
- "Add README badge" -> `auto-implement`
- "Change font" -> `frontend`
- "Password reset email" -> `backend`
- "Add a loading spinner to login" -> `fullstack` (needs API response state)

### Multi-issue (read `multi-issue.md`)

- "Add payment feature" -> split: backend (API + DB) → frontend (UI) → tests
- "Add social login" -> split: backend (OAuth API) → frontend (login UI + buttons)
- "Add push notifications" -> split: backend (notification service) → frontend (permission + UI)
- "Add chat feature" -> split: backend (messaging API + WebSocket) → frontend (chat UI) → tests

## When uncertain

Ask the user: "This looks like a large feature. Should I split it into phases (backend → frontend → tests), or implement it all at once?"
