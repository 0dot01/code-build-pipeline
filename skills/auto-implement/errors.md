# Error Handling

| Scenario | How to detect | Response |
|----------|--------------|----------|
| Docker image missing | `docker images claude-worker` returns nothing | Suggest `docker build -t claude-worker ./pipeline/` |
| Container stuck (>24h) | `docker ps --filter name=pipeline-` shows long uptime | Kill and offer retry |
| API key missing/expired | Script error contains "ANTHROPIC_API_KEY" | Ask user to check key |
| gh auth failure | Script error contains "gh auth" | Suggest `gh auth login` |
| Branch conflict | PR creation fails | Delete existing branch: `git push origin --delete feat/issue-N`, retry |
| Disk full | Docker error | Suggest `docker system prune` |
| Duplicate container | Same issue run twice | Script auto-kills existing container before starting |
