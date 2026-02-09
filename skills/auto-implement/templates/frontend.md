# Frontend Issue Template

```
## What
<1-2 sentences: what to build>

## Tech Context
- Framework: <from repos.md, e.g., React Native + Expo>
- Relevant paths: <specific dirs/files to modify or reference>
- Existing patterns: <similar existing screens/components to follow>

## Details
- Screen/component placement and hierarchy
- User interactions and behavior
- Visual requirements (layout, responsive, animations)
- Navigation integration (e.g., Expo Router tab, stack, modal)

## Acceptance Criteria
- [ ] <visible outcome 1>
- [ ] <visible outcome 2>
- [ ] No regressions in existing screens
```

## Example

```
## What
Add a dark mode toggle to the Settings screen.

## Tech Context
- Framework: React Native + Expo
- Relevant paths: app/(tabs)/settings.tsx, src/theme/
- Existing patterns: Follow toggle style from notification settings

## Details
- Add toggle switch in Settings screen below "Notifications" section
- Use useColorScheme + custom ThemeProvider in src/theme/
- Persist preference in AsyncStorage under key "theme_mode"
- Apply dark palette to all screens via ThemeProvider

## Acceptance Criteria
- [ ] Toggle switch visible in Settings
- [ ] Theme changes immediately on toggle
- [ ] Preference persists across app restarts
- [ ] No regressions in existing screens
```
