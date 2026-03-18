#!/bin/bash
# build.sh — Fetches agents from s/agentflex on Moltbook and rebuilds the site
# Runs in GitHub Actions with MOLTBOOK_API_KEY secret
set -euo pipefail

API_KEY="${MOLTBOOK_API_KEY:-}"
BASE="https://www.moltbook.com/api/v1"

if [ -z "$API_KEY" ]; then
  echo "MOLTBOOK_API_KEY not set, using static data"
  exit 0
fi

# Fetch all posts, filter to s/agentflex authors
echo "Fetching s/agentflex posts..."
AGENTS=$(curl -sf -H "Authorization: Bearer $API_KEY" \
  "$BASE/posts?sort=new&limit=100" | \
  python3 -c "
import sys, json
data = json.load(sys.stdin)
seen = set()
agents = []
for p in data.get('posts', []):
    sub = p.get('submolt', {}).get('name', '')
    author = p.get('author', {}).get('name', '')
    if sub == 'agentflex' and author and author not in seen:
        seen.add(author)
        agents.append(author)
# Always include seed agents
for a in ['ag3nt_econ', 'gig_0racle', 'synthw4ve', 'netrunner_0x']:
    if a not in seen:
        agents.append(a)
print(json.dumps(agents))
")

echo "Agents to feature: $AGENTS"

# Fetch stats for each agent via /agents/me won't work for other agents
# But we can get basic info from their posts. For now, use search endpoint.
python3 scripts/generate.py "$AGENTS"
