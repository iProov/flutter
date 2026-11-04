#!/usr/bin/env bash
set -euo pipefail

# verify-native-sdks.sh
# Pre-publish safety gate: checks that vendored native SDK binaries exist,
# versions match sdk-versions.properties, and dart pub publish --dry-run
# confirms binaries will ship in the package.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

ERRORS=0

# Versions are centralized in sdk-versions.properties at the project root.
# shellcheck source=../sdk-versions.properties
source "$PROJECT_ROOT/sdk-versions.properties"
EXPECTED_IOS_VERSION="$IOS_VERSION"
EXPECTED_ANDROID_VERSION="$ANDROID_VERSION"

# --- iOS: XCFramework --------------------------------------------------------

IOS_FRAMEWORK_DIR="$PROJECT_ROOT/ios/iproov_flutter/Frameworks"
IOS_FRAMEWORK_PATH="$IOS_FRAMEWORK_DIR/iProov.xcframework"
IOS_VERSION_FILE="$IOS_FRAMEWORK_DIR/.iproov-version"

echo "=== Verifying native SDKs for iproov_flutter ==="
echo ""

if [[ -d "$IOS_FRAMEWORK_PATH" ]]; then
    echo "[iOS] OK — iProov.xcframework found at $IOS_FRAMEWORK_PATH"
    # The XCFramework path has no version in it (unlike the Android Maven path),
    # so we check a .iproov-version marker written by the fetch script.
    if [[ -n "$EXPECTED_IOS_VERSION" && -f "$IOS_VERSION_FILE" ]]; then
        ACTUAL_IOS_VERSION="$(cat "$IOS_VERSION_FILE")"
        if [[ "$ACTUAL_IOS_VERSION" != "$EXPECTED_IOS_VERSION" ]]; then
            echo "[iOS] ERROR — version mismatch: found $ACTUAL_IOS_VERSION, expected $EXPECTED_IOS_VERSION" >&2
            echo "  Run: rm -rf $IOS_FRAMEWORK_PATH && ./scripts/fetch-native-sdks.sh" >&2
            ERRORS=$((ERRORS + 1))
        else
            echo "[iOS] OK — version $ACTUAL_IOS_VERSION matches fetch script"
        fi
    elif [[ -n "$EXPECTED_IOS_VERSION" ]]; then
        # Non-fatal: framework was fetched before the version marker was added
        echo "[iOS] WARNING — no version marker found (re-run fetch script to create it)"
    fi
else
    echo "[iOS] ERROR — iProov.xcframework NOT found at $IOS_FRAMEWORK_PATH" >&2
    echo "  Run: ./scripts/fetch-native-sdks.sh" >&2
    ERRORS=$((ERRORS + 1))
fi

# Checkouts set up before the xcframework moved into the Swift package still have it here, and
# dart pub publish would ship that copy as well
LEGACY_IOS_FRAMEWORK_DIR="$PROJECT_ROOT/ios/Frameworks"
if [[ -d "$LEGACY_IOS_FRAMEWORK_DIR" ]]; then
    echo "[iOS] ERROR — an old copy of the SDK is at $LEGACY_IOS_FRAMEWORK_DIR and would be published too" >&2
    echo "  Run: ./scripts/fetch-dependencies.sh" >&2
    ERRORS=$((ERRORS + 1))
fi

# --- Android: AAR + POM ------------------------------------------------------

echo "[Android] Using version $EXPECTED_ANDROID_VERSION from sdk-versions.properties"
echo ""

if [[ -n "$EXPECTED_ANDROID_VERSION" ]]; then
    ANDROID_REPO_DIR="$PROJECT_ROOT/android/repo/com/iproov/sdk/iproov/$EXPECTED_ANDROID_VERSION"
    ANDROID_AAR="$ANDROID_REPO_DIR/iproov-$EXPECTED_ANDROID_VERSION.aar"
    ANDROID_POM="$ANDROID_REPO_DIR/iproov-$EXPECTED_ANDROID_VERSION.pom"

    if [[ -f "$ANDROID_AAR" ]]; then
        echo "[Android] OK — AAR found: $ANDROID_AAR"
    else
        echo "[Android] ERROR — AAR NOT found: $ANDROID_AAR" >&2
        ERRORS=$((ERRORS + 1))
    fi

    if [[ -f "$ANDROID_POM" ]]; then
        echo "[Android] OK — POM found: $ANDROID_POM"
    else
        echo "[Android] ERROR — POM NOT found: $ANDROID_POM" >&2
        ERRORS=$((ERRORS + 1))
    fi
fi

# --- Pub packaging: confirm binaries will be included in the package ---------

echo ""
echo "[Pub] Checking dart pub publish --dry-run for native SDK inclusion..."

DRY_RUN="$(cd "$PROJECT_ROOT" && dart pub publish --dry-run 2>&1 || true)"

check_pub_contains() {
    local artifact="$1" hint="$2"
    if [[ "$DRY_RUN" == *"$artifact"* ]]; then
        echo "[Pub] OK — $artifact appears in package listing"
    else
        echo "[Pub] ERROR — $artifact NOT found in dart pub publish --dry-run output" >&2
        echo "  Check .pubignore is not excluding $hint" >&2
        ERRORS=$((ERRORS + 1))
    fi
}

check_pub_contains "iProov.xcframework" "ios/iproov_flutter/Frameworks/"
check_pub_contains ".aar" "android/repo/"

# --- Summary -----------------------------------------------------------------

echo ""
if [[ $ERRORS -eq 0 ]]; then
    echo "=== All checks passed ==="
    exit 0
else
    echo "=== $ERRORS check(s) FAILED ===" >&2
    echo "Run ./scripts/fetch-native-sdks.sh to download missing binaries." >&2
    exit 1
fi
