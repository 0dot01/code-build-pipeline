# Bugfix Issue Template

```
## What (REQUIRED)
<1-2 sentences: what's broken>
<!-- Agent needs this to: understand the bug before investigating code -->

## Reproduction (REQUIRED)
1. <step 1>
2. <step 2>
3. <observed behavior>
<!-- Agent needs this to: verify the bug exists and confirm the fix works.
     Without reproduction steps, the agent may fix the wrong thing. -->

## Expected Behavior (REQUIRED)
<what should happen instead>
<!-- Agent needs this to: know what "fixed" looks like -->

## Likely Location (REQUIRED)
- Files: <suspected files/dirs based on tech stack>
- Hypothesis: <probable cause if inferable>
<!-- Agent needs this to: start investigating in the right place.
     Without this, the investigator agents scan the entire codebase.
     Even a rough hypothesis dramatically speeds up the fix. -->

## Acceptance Criteria (REQUIRED)
- [ ] Bug no longer reproduces
- [ ] No regressions
<!-- Agent needs this to: verify the fix is complete.
     Include specific regression checks if the fix area is sensitive. -->
```

If the user provides an error message or stack trace, include it verbatim in a `## Error` section between What and Reproduction.

## Example

```
## What
App crashes when tapping "Save" on the profile edit screen with an empty name field.

## Error
TypeError: Cannot read property 'trim' of undefined
  at ProfileEditScreen (app/(tabs)/profile/edit.tsx:42)

## Reproduction
1. Go to Profile → Edit
2. Clear the name field completely
3. Tap "Save"
4. App crashes with TypeError

## Expected Behavior
Show validation error "Name is required" instead of crashing.

## Likely Location
- Files: app/(tabs)/profile/edit.tsx:42, lib/validation.ts
- Hypothesis: name field is undefined when empty (not empty string), and .trim() is called without null check

## Acceptance Criteria
- [ ] Empty name shows validation error "Name is required"
- [ ] Save button disabled when name is empty
- [ ] No crash on empty fields
- [ ] Other profile fields still save correctly
```
