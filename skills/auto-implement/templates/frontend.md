# Frontend Issue Template

```
## What
<1-2 sentences: what to build>

## Tech Context
- Framework: <from repos.md>
- Relevant paths: <specific dirs/files to modify or reference>
- Existing patterns: <similar existing screens/components to follow>

## Details
- Screen/component placement and hierarchy
- User interactions and behavior
- Visual requirements (layout, responsive, animations)
- Navigation integration (route, tab, modal)

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
- Framework: <from repos.md>
- Relevant paths: src/pages/settings.tsx, src/theme/
- Existing patterns: Follow toggle style from notification settings

## Details
- Add toggle switch in Settings page below "Notifications" section
- Use theme context + custom ThemeProvider in src/theme/
- Persist preference in local storage under key "theme_mode"
- Apply dark palette to all pages via ThemeProvider

## Acceptance Criteria
- [ ] Toggle switch visible in Settings
- [ ] Theme changes immediately on toggle
- [ ] Preference persists across app restarts
- [ ] No regressions in existing screens
```
