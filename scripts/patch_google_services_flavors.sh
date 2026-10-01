#!/usr/bin/env bash
# Adds dev/staging Android package names to google-services.json using prod credentials.
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GS_JSON="${1:-$PROJECT_ROOT/android/app/google-services.json}"

if [[ ! -f "$GS_JSON" ]]; then
  echo "ERROR: $GS_JSON not found. Run flutterfire configure first."
  exit 1
fi

python3 - "$GS_JSON" <<'PY'
import copy
import json
import sys

path = sys.argv[1]
packages = [
    "com.chessapp.chess.dev",
    "com.chessapp.chess.staging",
    "com.chessapp.chess",
]

with open(path, encoding="utf-8") as f:
    data = json.load(f)

clients = data.get("client", [])
by_package = {
    c["client_info"]["android_client_info"]["package_name"]: c for c in clients
}

template = by_package.get("com.chessapp.chess") or (clients[0] if clients else None)
if template is None:
    print("ERROR: No client entry found in google-services.json", file=sys.stderr)
    sys.exit(1)

for package in packages:
    if package not in by_package:
        entry = copy.deepcopy(template)
        entry["client_info"]["android_client_info"]["package_name"] = package
        clients.append(entry)

data["client"] = clients
with open(path, "w", encoding="utf-8") as f:
    json.dump(data, f, indent=2)
    f.write("\n")

print(f"Patched {path} with all flavor package names (prod credentials).")
PY
