#!/usr/bin/env bash
set -euo pipefail

FLAVOR="${1:-dev}"
TARGETS="${2:-firestore,functions}"
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

PROJECT_ID="chess-347ba"

echo "==> Deploying $TARGETS to $PROJECT_ID (flavor: $FLAVOR)"

firebase use "$PROJECT_ID"

echo "==> Building Cloud Functions..."
(cd functions && npm run build)

echo "==> Deploying..."
firebase deploy --only "$TARGETS"

echo "==> Deploy complete."
