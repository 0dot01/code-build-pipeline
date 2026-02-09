# Bugfix Issue Template

```
## What
<1-2 sentences: what's broken>

## Reproduction
1. <step 1>
2. <step 2>
3. <observed behavior>

## Expected Behavior
<what should happen instead>

## Likely Location
- Files: <suspected files/dirs based on tech stack>
- Hypothesis: <probable cause if inferable>

## Acceptance Criteria
- [ ] Bug no longer reproduces
- [ ] No regressions
```

If the user provides an error message or stack trace, include it verbatim in a `## Error` section between What and Reproduction.

## Example

```
## What
App crashes when tapping "Save" on the profile edit screen with an empty name field.

## Error
TypeError: Cannot read property 'trim' of undefined
  at ProfileEditScreen (src/screens/profile/EditProfile.tsx:42)

## Reproduction
1. Go to Profile → Edit
2. Clear the name field completely
3. Tap "Save"
4. App crashes with TypeError

## Expected Behavior
Show validation error "Name is required" instead of crashing.

## Likely Location
- Files: src/screens/profile/EditProfile.tsx:42
- Hypothesis: name field is undefined when empty (not empty string), and .trim() is called without null check

## Acceptance Criteria
- [ ] Empty name shows validation error
- [ ] Save button disabled when name is empty
- [ ] No crash on empty fields
```
