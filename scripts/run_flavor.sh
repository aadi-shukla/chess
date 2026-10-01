#!/usr/bin/env bash
set -euo pipefail

FLAVOR="${1:-dev}"

case "$FLAVOR" in
  dev)
    TARGET="lib/main_dev.dart"
    ENV_FILE="config/env/dev.json"
    ;;
  staging)
    TARGET="lib/main_staging.dart"
    ENV_FILE="config/env/staging.json"
    ;;
  prod)
    TARGET="lib/main_prod.dart"
    ENV_FILE="config/env/prod.json"
    ;;
  *)
    echo "Unknown flavor: $FLAVOR (use dev, staging, or prod)"
    exit 1
    ;;
esac

flutter run -t "$TARGET" --dart-define-from-file="$ENV_FILE" --flavor "$FLAVOR" "${@:2}"
