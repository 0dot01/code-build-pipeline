# Multi-Issue Sub-Issue Template

For sub-issues created via `multi-issue.md`. Each phase gets its own issue with scoped boundaries.

```
## Parent (REQUIRED)
Part of #<root_issue_number>: <root issue title>
<!-- Agent needs this to: understand this is part of a larger feature and check the parent for context -->

## What (REQUIRED)
<what THIS phase implements — scoped to this phase only>
<!-- Agent needs this to: understand the goal of THIS phase without over-building -->

## Tech Context (REQUIRED)
<tech stack info relevant to this phase only>
<!-- Agent needs this to: find the right files for this specific phase -->

## Details (REQUIRED)
<phase-specific implementation details>

## Scope Boundary (REQUIRED)
- IN scope: <what this phase covers>
- OUT of scope: <what other phases handle — be explicit>
<!-- Agent needs this to: avoid implementing work from other phases.
     This is THE MOST CRITICAL section for sub-issues. Without it,
     the agent will over-build and create merge conflicts with other phases. -->

## Depends On (REQUIRED)
<"None" for Phase 1, or list prior phase numbers with their issue numbers>
<!-- Agent needs this to: know if it can assume prior work exists (merged branches, new models, etc.) -->

## Acceptance Criteria (REQUIRED)
- [ ] <phase-specific outcome>
<!-- Agent needs this to: verify only this phase's work is complete -->
```

The **Scope Boundary** section is critical. It prevents Claude Code from implementing work that belongs to another phase.

## Example (Phase 1: Backend)

```
## Parent
Part of #10: Add payment system

## What
Implement payment API endpoints and database schema.

## Tech Context
- Framework: AWS Amplify Gen 2, AppSync GraphQL
- Relevant paths: amplify/data/resource.ts, amplify/auth/
- Existing patterns: Follow existing Order model and CRUD resolvers

## Details
- Add Payment model: id, userId, amount, currency, status, createdAt
- Add PaymentMethod model: id, userId, type, last4, isDefault
- Mutations: createPayment, getPayment, listPaymentsByUser
- Stripe integration (stripe npm package) via Lambda resolver
- Auth: owner can read own payments, admin can read all

## Scope Boundary
- IN scope: GraphQL schema, resolvers, Stripe integration, auth rules
- OUT of scope: Payment UI screens (Phase 2), E2E tests (Phase 3)

## Depends On
None (first phase)

## Acceptance Criteria
- [ ] Payment and PaymentMethod models in schema
- [ ] CRUD mutations/queries working via AppSync
- [ ] Stripe charge creation working
- [ ] Auth rules enforced (owner-only reads)
```

## Example (Phase 2: Frontend, depends on Phase 1)

```
## Parent
Part of #10: Add payment system

## What
Build payment UI screens consuming the API from Phase 1.

## Tech Context
- Framework: React Native + Expo (SDK 52)
- Relevant paths: app/(tabs)/payments/, components/payment/
- Existing patterns: Follow existing order list page layout in app/(tabs)/orders/

## Details
- Payment history page: list user's payments (listPaymentsByUser query)
- Add payment method page: card input form (Stripe Elements)
- Checkout flow: select method → confirm amount → createPayment mutation
- Loading states, error handling, empty states
- Navigation: add "Payments" tab in bottom nav
- i18n: add keys for all payment-related strings

## Scope Boundary
- IN scope: All payment UI screens, navigation, state management
- OUT of scope: API/DB changes (Phase 1, already merged), E2E tests (Phase 3)

## Depends On
Phase 1: #11 (API and DB schema must be merged first)

## Acceptance Criteria
- [ ] Payment history screen shows past payments
- [ ] Add payment method flow works
- [ ] Checkout flow creates payment via API
- [ ] Proper loading/error/empty states
- [ ] Payments tab accessible from bottom nav
```
