# Backend Issue Template

```
## What (REQUIRED)
<1-2 sentences: what to build>
<!-- Agent needs this to: understand the goal before reading code -->

## Tech Context (REQUIRED)
- Framework: <from repos.md — e.g., "AWS Amplify Gen 2, AppSync GraphQL">
- Relevant paths: <API dirs, schema files, config>
- Existing patterns: <similar existing endpoints/models to follow>
<!-- Agent needs this to: find the right files and match existing API patterns.
     Without this, the agent may create endpoints in wrong locations or use wrong conventions. -->

## Details (REQUIRED)
- Endpoints / mutations / queries (method, path, request/response shape)
- Data model changes (new fields, new tables, relationships)
- Auth/permission requirements
- Error handling expectations
- Validation rules
<!-- Agent needs this to: implement the exact API contract. Be explicit about field names,
     types, and auth rules. Ambiguity here causes frontend/backend mismatches. -->

## Acceptance Criteria (REQUIRED)
- [ ] <API behavior 1>
- [ ] <data persistence 1>
- [ ] Existing tests still pass
<!-- Agent needs this to: verify the implementation is complete and correct.
     Each item must be a verifiable outcome. -->
```

## Example

```
## What
Add password reset API endpoint.

## Tech Context
- Framework: AWS Amplify Gen 2, Cognito
- Relevant paths: amplify/auth/, amplify/data/resource.ts
- Existing patterns: Follow existing auth flow in amplify/auth/resource.ts

## Details
- POST /auth/reset-password: { email } → { success, message }
- POST /auth/confirm-reset: { email, code, newPassword } → { success }
- Rate limit: max 3 requests per email per hour
- Send reset code via Cognito email service
- Code expires after 15 minutes
- Validation: email format, password min 8 chars

## Acceptance Criteria
- [ ] Reset request sends email with 6-digit code
- [ ] Confirm endpoint validates code and updates password
- [ ] Expired/invalid codes return 400
- [ ] Rate limiting enforced
- [ ] Existing auth tests still pass
```
