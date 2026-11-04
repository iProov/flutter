#!/usr/bin/env bash
set -euo pipefail

# Cleans vendored native SDK binaries and re-fetches them from scratch.
# Run this once after cloning, or whenever sdk-versions.properties changes.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# --- Clean previous binaries -------------------------------------------------

echo "=== Cleaning previous native SDK binaries ==="
echo ""

IOS_FRAMEWORK_DIR="$PROJECT_ROOT/ios/iproov_flutter/Frameworks"
ANDROID_REPO_DIR="$PROJECT_ROOT/android/repo"

if [[ -d "$IOS_FRAMEWORK_DIR" ]]; then
    echo "[iOS] Removing $IOS_FRAMEWORK_DIR..."
    rm -rf "$IOS_FRAMEWORK_DIR"
fi

# Remove binaries downloaded before the Swift Package Manager directory migration.
rm -rf "$PROJECT_ROOT/ios/Frameworks"

if [[ -d "$ANDROID_REPO_DIR" ]]; then
    echo "[Android] Removing $ANDROID_REPO_DIR..."
    rm -rf "$ANDROID_REPO_DIR"
fi

echo ""

# --- Fetch and verify --------------------------------------------------------

"$SCRIPT_DIR/fetch-native-sdks.sh"
echo ""
"$SCRIPT_DIR/verify-native-sdks.sh"
