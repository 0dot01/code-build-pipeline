# Known Repos

Add repos here as they are used with the pipeline. The orchestrator reads this file to infer tech stack details when generating issue bodies.

## Format

```markdown
## owner/repo

- **Stack**: (e.g., React Native + Expo, Next.js, Django + React)
- **Language**: (e.g., TypeScript, Python, Go)
- **Structure**: (e.g., file-based routing, monorepo, microservices)
- **Default label hint**: (e.g., mostly `frontend`, `backend`, `fullstack`)
- **Build**: (e.g., Yarn 4, npm, Poetry)
- **Tests**: (e.g., Jest, pytest, Go test)
- **CI**: (e.g., GitHub Actions)
- **Context files**: (e.g., `CLAUDE.md`, `.claude/`)
```
