#!/usr/bin/env bash
set -euo pipefail

FLAVOR="${1:-dev}"
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

PROJECT_ID="chess-347ba"

echo "==> Starting Firebase emulators for $PROJECT_ID (flavor: $FLAVOR)"
firebase use "$PROJECT_ID"
firebase emulators:start --import=./firebase/emulator-data --export-on-exit
