# Generic Issue Template

Use when the label is `auto-implement` (no sub-type). Claude Code will decide the approach.

```
## What
<1-2 sentences: what to do>

## Why
<why this is needed>

## Details
- Specific requirements
- Files or areas to reference
- Constraints or preferences

## Acceptance Criteria
- [ ] <outcome 1>
- [ ] <outcome 2>
```

## Example

```
## What
Add a build version badge to the README.

## Why
Contributors should see build status at a glance.

## Details
- Add GitHub Actions badge for the deploy.yml workflow
- Place it at the top of README.md, below the title
- Use the standard GitHub badge format

## Acceptance Criteria
- [ ] Badge visible at top of README
- [ ] Badge links to the Actions workflow
- [ ] Badge shows current build status (passing/failing)
```
