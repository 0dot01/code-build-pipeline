# Fullstack Issue Template

Use for small features requiring both frontend and backend. For large features, use `multi-issue.md` instead.

```
## What (REQUIRED)
<1-2 sentences: what to build>
<!-- Agent needs this to: understand the goal before reading code -->

## Tech Context (REQUIRED)
- Frontend: <framework, relevant paths>
- Backend: <framework, relevant paths>
- Existing patterns: <similar existing features to follow>
<!-- Agent needs this to: navigate directly to frontend AND backend files.
     Both fe-builder and be-builder agents read this section to find their starting points.
     Without specific paths, both agents waste time searching independently. -->

## API Contract (REQUIRED)
- <endpoint/mutation name>: <request shape> → <response shape>
<!-- Agent needs this to: ensure frontend and backend agents agree on the interface.
     This is the MOST CRITICAL section for fullstack issues. Without it,
     frontend may call an endpoint that backend implements differently. -->

## Frontend Details (REQUIRED)
- UI placement, interactions, state management
- How the UI calls the API (hook, service, direct fetch)
- i18n keys needed
- Dark mode considerations
<!-- Agent needs this to: implement the UI correctly. The fe-builder agent reads this section. -->

## Backend Details (REQUIRED)
- Endpoints, data model, auth
- Validation and error responses
<!-- Agent needs this to: implement the API correctly. The be-builder agent reads this section. -->

## Acceptance Criteria (REQUIRED)
- [ ] <end-to-end outcome 1>
- [ ] <end-to-end outcome 2>
<!-- Agent needs this to: verify the full feature works end-to-end.
     Each item must be a verifiable end-user outcome. -->
```

## Example

```
## What
Add "last seen" status to user profiles.

## Tech Context
- Frontend: React Native + Expo (SDK 52), app/(tabs)/profile.tsx, components/
- Backend: AWS Amplify Gen 2, amplify/data/resource.ts
- Existing patterns: Follow existing User model in amplify/data/ and profile page layout

## API Contract
- GET user query → { ...existing, lastSeen: AWSDateTime }
- Mutation updateLastSeen → { lastSeen } (called on app foreground)

## Frontend Details
- Show "Active now" / "5m ago" / "2h ago" below username on profile screen
- Call updateLastSeen mutation on AppState "active" event
- Use relative time formatting (date-fns formatDistanceToNow)
- Add i18n keys: `profile.lastSeen`, `profile.activeNow`

## Backend Details
- Add lastSeen: AWSDateTime field to User model in amplify/data/resource.ts
- updateLastSeen mutation: set to current timestamp, auth: owner only
- User query: include lastSeen in response, auth: any authenticated user can read

## Acceptance Criteria
- [ ] lastSeen updates when user opens app
- [ ] Profile screen shows relative time below username
- [ ] Other users can see the last seen time
- [ ] Guest users cannot see last seen
```
