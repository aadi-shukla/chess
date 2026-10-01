#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# Firebase + FlutterFire one-time setup script
# Run from project root: ./scripts/firebase_setup.sh [dev|staging|prod]
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

FLAVOR="${1:-dev}"
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

echo "==> Chess Firebase Setup (flavor: $FLAVOR)"
echo ""

# ── 1. Node.js (required for Firebase CLI + Cloud Functions) ─────────────────
if ! command -v node &>/dev/null; then
  echo "ERROR: Node.js is required. Install from https://nodejs.org (LTS v20+)."
  exit 1
fi
echo "✓ Node.js $(node --version)"

# ── 2. Firebase CLI ─────────────────────────────────────────────────────────
if ! command -v firebase &>/dev/null; then
  echo "==> Installing Firebase CLI globally..."
  npm install -g firebase-tools
fi
echo "✓ Firebase CLI $(firebase --version)"

# ── 3. FlutterFire CLI ────────────────────────────────────────────────────────
if ! command -v flutterfire &>/dev/null; then
  echo "==> Activating FlutterFire CLI..."
  dart pub global activate flutterfire_cli
fi
echo "✓ FlutterFire CLI installed"

# Ensure pub global bin is on PATH
export PATH="$PATH:$HOME/.pub-cache/bin"

# ── 4. Firebase login ─────────────────────────────────────────────────────────
echo ""
echo "==> Logging into Firebase (browser will open if needed)..."
firebase login

# ── 5. Select Firebase project (single prod project for all flavors) ───────────
PROJECT_ID="chess-347ba"

echo ""
echo "==> Using Firebase project: $PROJECT_ID (all flavors share prod credentials)"
firebase use "$PROJECT_ID" --add 2>/dev/null || firebase use "$PROJECT_ID"

# ── 6. FlutterFire configure (generates firebase_options.dart + platform files) ─
echo ""
echo "==> Running FlutterFire configure for all platforms..."
flutterfire configure \
  --project="$PROJECT_ID" \
  --out=lib/app/config/firebase_options.dart \
  --platforms=android,ios,macos,web,windows \
  --android-package-name="com.chessapp.chess" \
  --ios-bundle-id="com.chessapp.chess" \
  --macos-bundle-id="com.chessapp.chess" \
  --yes

echo ""
echo "==> Patching google-services.json for all Android flavor package names..."
chmod +x scripts/patch_google_services_flavors.sh
./scripts/patch_google_services_flavors.sh

# ── 7. Install Cloud Functions dependencies ───────────────────────────────────
echo ""
echo "==> Installing Cloud Functions dependencies..."
(cd functions && npm install)

# ── 8. Enable Firebase services in Console (manual reminder) ──────────────────
echo ""
echo "════════════════════════════════════════════════════════════════════════"
echo " MANUAL STEPS in Firebase Console (https://console.firebase.google.com)"
echo "════════════════════════════════════════════════════════════════════════"
echo " 1. Authentication → Sign-in method → Enable:"
echo "    • Email/Password"
echo "    • Google (add SHA-1 for Android from: cd android && ./gradlew signingReport)"
echo "    • Apple (required if Google is enabled on iOS)"
echo "    • Anonymous"
echo ""
echo " 2. Firestore Database → Create database → Production mode → select region"
echo ""
echo " 3. Functions → Upgrade to Blaze plan (required for Cloud Functions deploy)"
echo ""
echo " 4. (Recommended) App Check → Register apps"
echo "════════════════════════════════════════════════════════════════════════"
echo ""
echo "Setup complete. Next steps:"
echo "  ./scripts/run_emulators.sh          # local dev with emulators"
echo "  ./scripts/deploy_firebase.sh $FLAVOR # deploy rules + functions"
