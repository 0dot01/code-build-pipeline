# Backend Issue Template

```
## What
<1-2 sentences: what to build>

## Tech Context
- Framework: <from repos.md>
- Relevant paths: <API dirs, schema files, config>
- Existing patterns: <similar existing endpoints/models to follow>

## Details
- Endpoints / mutations / queries (method, path, request/response shape)
- Data model changes (new fields, new tables, relationships)
- Auth/permission requirements
- Error handling expectations

## Acceptance Criteria
- [ ] <API behavior 1>
- [ ] <data persistence 1>
- [ ] Existing tests still pass
```

## Example

```
## What
Add password reset API endpoint.

## Tech Context
- Framework: <from repos.md>
- Relevant paths: src/api/, src/models/
- Existing patterns: Follow existing auth flow

## Details
- POST /auth/reset-password: { email } → { success, message }
- POST /auth/confirm-reset: { email, code, newPassword } → { success }
- Rate limit: max 3 requests per email per hour
- Send reset code via email service
- Code expires after 15 minutes

## Acceptance Criteria
- [ ] Reset request sends email with 6-digit code
- [ ] Confirm endpoint validates code and updates password
- [ ] Expired/invalid codes return 400
- [ ] Rate limiting enforced
- [ ] Existing auth tests still pass
```
