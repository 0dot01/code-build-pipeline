# Frontend Issue Template

```
## What (REQUIRED)
<1-2 sentences: what to build>
<!-- Agent needs this to: understand the goal before reading code -->

## Tech Context (REQUIRED)
- Framework: <from repos.md — e.g., "React Native + Expo (SDK 52)">
- Relevant paths: <specific dirs/files to modify or reference>
- Existing patterns: <similar existing screens/components to follow>
<!-- Agent needs this to: navigate directly to the right files and match existing code style.
     Without this, the agent scans the entire codebase and may create files in wrong locations. -->

## Details (REQUIRED)
- Screen/component placement and hierarchy
- User interactions and behavior
- Visual requirements (layout, responsive, animations)
- Navigation integration (route, tab, modal)
- i18n: mention if user-facing strings need translation keys
- Dark mode: reference theme tokens/colors file if applicable
<!-- Agent needs this to: implement the feature correctly without guessing UI placement or behavior.
     Be specific: "below the hero section" not "on the home screen". -->

## Acceptance Criteria (REQUIRED)
- [ ] <visible outcome 1>
- [ ] <visible outcome 2>
- [ ] No regressions in existing screens
<!-- Agent needs this to: know when the task is complete and self-verify.
     Each item must be a testable end-user outcome, not an implementation step. -->
```

## Example

```
## What
Add a dark mode toggle to the Settings screen.

## Tech Context
- Framework: React Native + Expo (SDK 52)
- Relevant paths: app/(tabs)/settings.tsx, constants/Colors.ts, theme/
- Existing patterns: Follow toggle style from notification settings in app/(tabs)/settings.tsx

## Details
- Add toggle switch in Settings page below "Notifications" section
- Use theme context from theme/ThemeProvider.tsx + constants/Colors.ts
- Persist preference in AsyncStorage under key "theme_mode"
- Apply dark palette to all pages via ThemeProvider
- Add i18n key `settings.darkMode` in all locale files

## Acceptance Criteria
- [ ] Toggle switch visible in Settings below Notifications
- [ ] Theme changes immediately on toggle
- [ ] Preference persists across app restarts
- [ ] All screens render correctly in dark mode
- [ ] No regressions in existing screens
```
