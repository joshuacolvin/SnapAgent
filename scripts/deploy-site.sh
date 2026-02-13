#!/bin/bash
set -euo pipefail

# Deploy the landing page to Cloudflare Pages
# Site: https://snapagent.baxlylabs.com

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DOCS_DIR="$SCRIPT_DIR/../docs"

echo "==> Deploying site to Cloudflare Pages..."
wrangler pages deploy "$DOCS_DIR" --project-name snapagent --branch main

echo ""
echo "==> Done! Site is live at https://snapagent.baxlylabs.com"
