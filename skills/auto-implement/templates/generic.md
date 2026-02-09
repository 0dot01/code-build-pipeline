# Generic Issue Template

Use when the label is `auto-implement` (no sub-type). Claude Code will decide the approach.

```
## What (REQUIRED)
<1-2 sentences: what to do>
<!-- Agent needs this to: understand the goal before reading code -->

## Why (REQUIRED)
<why this is needed>
<!-- Agent needs this to: make better decisions when facing trade-offs -->

## Tech Context (REQUIRED)
- Relevant paths: <files or areas to reference>
- Existing patterns: <similar existing features to follow>
<!-- Agent needs this to: find the right files and match existing code style.
     Even for generic tasks, always provide at least one specific file path. -->

## Details (REQUIRED)
- Specific requirements
- Constraints or preferences
<!-- Agent needs this to: implement correctly without guessing.
     Be concrete: "Add badge below the title in README.md" not "Add a badge". -->

## Acceptance Criteria (REQUIRED)
- [ ] <outcome 1>
- [ ] <outcome 2>
<!-- Agent needs this to: know when the task is complete and self-verify. -->
```

## Example

```
## What
Add a build version badge to the README.

## Why
Contributors should see build status at a glance without navigating to Actions.

## Tech Context
- Relevant paths: README.md, .github/workflows/deploy.yml
- Existing patterns: No existing badges — this will be the first

## Details
- Add GitHub Actions badge for the deploy.yml workflow
- Place it at the top of README.md, below the title line
- Use the standard GitHub badge format: `![Deploy](https://github.com/...)`
- Link the badge to the Actions workflow page

## Acceptance Criteria
- [ ] Badge visible at top of README below title
- [ ] Badge links to the Actions workflow
- [ ] Badge shows current build status (passing/failing)
```
