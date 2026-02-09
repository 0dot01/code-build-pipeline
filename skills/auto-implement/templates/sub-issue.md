# Multi-Issue Sub-Issue Template

For sub-issues created via `multi-issue.md`. Each phase gets its own issue with scoped boundaries.

```
## Parent
Part of #<root_issue_number>: <root issue title>

## What
<what THIS phase implements — scoped to this phase only>

## Tech Context
<tech stack info relevant to this phase only>

## Details
<phase-specific implementation details>

## Scope Boundary
- IN scope: <what this phase covers>
- OUT of scope: <what other phases handle — be explicit>

## Depends On
<"None" for Phase 1, or list prior phase numbers>

## Acceptance Criteria
- [ ] <phase-specific outcome>
```

The **Scope Boundary** section is critical. It prevents Claude Code from implementing work that belongs to another phase.

## Example (Phase 1: Backend)

```
## Parent
Part of #10: Add payment system

## What
Implement payment API endpoints and database schema.

## Tech Context
- Framework: AWS Amplify + Lambda
- Relevant paths: amplify/backend/api/, amplify/backend/function/
- Existing patterns: Follow existing order model and CRUD resolvers

## Details
- Add Payment model: id, userId, amount, currency, status, createdAt
- Add PaymentMethod model: id, userId, type, last4, isDefault
- GraphQL mutations: createPayment, updatePaymentStatus
- GraphQL queries: getPayment, listPaymentsByUser
- Stripe integration via Lambda function (stripe npm package)
- Auth: owner can read own payments, admin can read all

## Scope Boundary
- IN scope: API endpoints, DB schema, Stripe Lambda, auth rules
- OUT of scope: Payment UI screens (Phase 2), E2E tests (Phase 3)

## Depends On
None (first phase)

## Acceptance Criteria
- [ ] Payment and PaymentMethod models in schema
- [ ] CRUD resolvers working via GraphQL
- [ ] Stripe charge creation via Lambda
- [ ] Auth rules enforced (owner-only reads)
```

## Example (Phase 2: Frontend, depends on Phase 1)

```
## Parent
Part of #10: Add payment system

## What
Build payment UI screens consuming the API from Phase 1.

## Tech Context
- Framework: React Native + Expo
- Relevant paths: app/(tabs)/payments/, src/components/payment/
- Existing patterns: Follow existing order list screen layout

## Details
- Payment history screen: list user's payments (listPaymentsByUser query)
- Add payment method screen: card input form (Stripe Elements or manual)
- Checkout flow: select method → confirm amount → createPayment mutation
- Loading states, error handling, empty states
- Navigation: add "Payments" tab in bottom nav via Expo Router

## Scope Boundary
- IN scope: All payment UI screens, navigation, state management
- OUT of scope: API/DB changes (Phase 1, already done), E2E tests (Phase 3)

## Depends On
Phase 1: #11 (API and DB schema must be merged first)

## Acceptance Criteria
- [ ] Payment history screen shows past payments
- [ ] Add payment method flow works
- [ ] Checkout flow creates payment via API
- [ ] Proper loading/error/empty states
- [ ] Payments tab accessible from bottom nav
```
