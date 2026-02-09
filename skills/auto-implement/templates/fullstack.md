# Fullstack Issue Template

Use for small features requiring both frontend and backend. For large features, use `multi-issue.md` instead.

```
## What
<1-2 sentences: what to build>

## Tech Context
- Frontend: <framework, relevant paths>
- Backend: <framework, relevant paths>
- Existing patterns: <similar existing features to follow>

## API Contract
- <endpoint/mutation name>: <request shape> → <response shape>

## Frontend Details
- UI placement, interactions, state management
- How the UI calls the API (hook, service, direct fetch)

## Backend Details
- Endpoints, data model, auth
- Validation and error responses

## Acceptance Criteria
- [ ] <end-to-end outcome 1>
- [ ] <end-to-end outcome 2>
```

## Example

```
## What
Add "last seen" status to user profiles.

## Tech Context
- Frontend: <from repos.md>, src/pages/profile.tsx
- Backend: <from repos.md>, src/api/users/
- Existing patterns: Follow existing User model and profile page

## API Contract
- GET /api/users/:id → { ...existing, lastSeen: ISO8601 }
- POST /api/users/heartbeat → { lastSeen } (called on app foreground)

## Frontend Details
- Show "Active now" / "5m ago" / "2h ago" below username on profile
- Call heartbeat endpoint on app foreground event
- Use relative time formatting (date-fns or similar)

## Backend Details
- Add lastSeen field to User model
- Heartbeat endpoint: set to current timestamp, auth: owner only
- User query: include lastSeen in response

## Acceptance Criteria
- [ ] lastSeen updates when user opens app
- [ ] Profile screen shows relative time
- [ ] Other users can see the last seen time
```
