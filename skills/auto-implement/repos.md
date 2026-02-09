# Known Repos

The orchestrator reads this file to infer tech stack details when generating issue bodies.

> **RULE: If the target repo is NOT listed here, ask the user for tech stack info before creating the issue.
> Never generate an issue body with `<from repos.md>` placeholders — that produces unusable issues.**

## How to add a repo

When a new repo is first used with the pipeline, add an entry following this format. The more detail here, the better the generated issues.

---

## caesar-is-great/elyxs

- **Stack**: React Native + Expo (SDK 53) + AWS Amplify Gen 2
- **Language**: TypeScript (strict mode)
- **Structure**: File-based routing via Expo Router
  - `app/(authenticated)/` — protected routes (home, chat, settings, inbox)
  - `app/(unauthenticated)/` — public routes (landing, login, signup)
  - `app/_layout.tsx` — root layout with provider hierarchy
- **Key paths**:
  - `components/screens/` — full-screen components (HomeScreen, InboxScreen, etc.)
  - `components/composites/` — complex components split by `common/`, `mobile/`, `web/`
  - `components/primitives/` — base UI elements
  - `components/layouts/` — platform-adaptive layouts
  - `lib/providers/` — React Context providers (Auth, Language, Profile, Inbox, Query, etc.)
  - `lib/hooks/` — custom hooks
  - `utils/` — utility functions
  - `theme/colors.ts` — color palette (dark/light)
  - `i18n/locales/` — 14 locales (en, ko, ja, zh-CN, zh-TW, ar, de, es, fr, hi, id, it, pt, th, vi)
  - `amplify/data/resource.ts` — GraphQL schema (ElyxsProfile, Flashcard, Inbox, Device, etc.)
  - `amplify/auth/` — Cognito triggers
  - `amplify/functions/` — Lambda functions (AI, stream handlers, custom resolvers, REST API)
  - `constants/` — app constants
- **Patterns**:
  - Controller pattern: logic in `*Controller.tsx`, rendering in `*.tsx`
  - Platform variants: `.web.tsx` / `.native.tsx` for platform-specific code
  - State: TanStack React Query v5 (server) + React Context (app) + AsyncStorage (local)
  - Forms: react-hook-form + zod validation
  - i18n: i18next with keys per locale, persist to AsyncStorage (`@elyxs_language`)
  - Dark mode: `useColorScheme` hook + `theme/colors.ts`
  - Auth: Cognito User Pool with custom Authenticator in `components/authenticator/`
  - AI: AWS Bedrock Claude Sonnet via `amplify/functions/ai/`
  - Subscriptions: RevenueCat
  - Analytics: PostHog + Firebase
- **Default label hint**: `frontend` (most features are UI-heavy)
- **Build**: Yarn 4 (node-modules linker)
- **Tests**: Playwright (E2E, web only) — `yarn test:e2e`
- **CI**: GitHub Actions (e2e.yml, deploy.yml, chromatic.yml, claude-code-review.yml)
- **Context files**: `CLAUDE.md` at project root
