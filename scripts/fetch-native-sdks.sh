#!/usr/bin/env bash
set -euo pipefail

# fetch-native-sdks.sh
# Downloads iProov native iOS and Android SDKs into the Flutter plugin's
# vendored directories. Idempotent — skips download if binaries already exist.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# --- Preflight ---------------------------------------------------------------

for cmd in curl unzip python3; do
    if ! command -v "$cmd" &>/dev/null; then
        echo "ERROR: Required command '$cmd' not found. Please install it and try again." >&2
        exit 1
    fi
done

# Portable SHA-256: macOS has shasum, Linux has sha256sum
if command -v shasum &>/dev/null; then
    sha256() { shasum -a 256 "$1" | awk '{print $1}'; }
elif command -v sha256sum &>/dev/null; then
    sha256() { sha256sum "$1" | awk '{print $1}'; }
else
    echo "ERROR: Neither 'shasum' nor 'sha256sum' found. Please install one and try again." >&2
    exit 1
fi

# --- Configuration -----------------------------------------------------------

# Versions are centralized in sdk-versions.properties at the project root.
# shellcheck source=../sdk-versions.properties
source "$PROJECT_ROOT/sdk-versions.properties"

IOS_FRAMEWORK_DIR="$PROJECT_ROOT/ios/iproov_flutter/Frameworks"
IOS_FRAMEWORK_PATH="$IOS_FRAMEWORK_DIR/iProov.xcframework"

ANDROID_REPO_DIR="$PROJECT_ROOT/android/repo/com/iproov/sdk/iproov/$ANDROID_VERSION"
ANDROID_AAR="$ANDROID_REPO_DIR/iproov-$ANDROID_VERSION.aar"
ANDROID_POM="$ANDROID_REPO_DIR/iproov-$ANDROID_VERSION.pom"

IOS_GITHUB_REPO="iProov/ios"
ANDROID_GITHUB_REPO="iProov/android"
ANDROID_MAVEN_BASE="https://raw.githubusercontent.com/$ANDROID_GITHUB_REPO/master/maven/com/iproov/sdk/iproov/$ANDROID_VERSION"

# --- Auth --------------------------------------------------------------------

get_github_token() {
    if [[ -n "${GITHUB_TOKEN:-}" ]]; then
        echo "$GITHUB_TOKEN"
    elif command -v gh &>/dev/null && gh auth status &>/dev/null; then
        gh auth token
    else
        echo ""
    fi
}

TOKEN="$(get_github_token)"

# Build auth args once upfront so curl_auth doesn't fork a subshell per call
if [[ -n "$TOKEN" ]]; then
    CURL_AUTH_ARGS=(-fSL -H "Authorization: token $TOKEN")
else
    CURL_AUTH_ARGS=(-fSL)
fi

curl_auth() {
    curl "${CURL_AUTH_ARGS[@]}" "$@"
}

# Validate a SHA-256 hash string (non-empty, 64 hex chars, not an error page)
is_valid_sha256() {
    local sha="$1"
    [[ -n "$sha" && ${#sha} -eq 64 && "$sha" =~ ^[0-9a-f]{64}$ ]]
}

# Verify a file's SHA-256 checksum. Exits on mismatch, warns if no valid checksum.
verify_sha256() {
    local label="$1" file="$2" expected="$3"
    if is_valid_sha256 "$expected"; then
        local actual
        actual="$(sha256 "$file")"
        if [[ "$actual" != "$expected" ]]; then
            echo "[$label] ERROR: SHA-256 mismatch!" >&2
            echo "  Expected: $expected" >&2
            echo "  Actual:   $actual" >&2
            exit 1
        fi
        echo "[$label] SHA-256 verified: $actual"
    else
        echo "[$label] WARNING: No valid SHA-256 checksum available — skipping verification."
    fi
}

# --- Downloads ---------------------------------------------------------------

# All downloads go here first; EXIT trap auto-cleans even on errors
TMPDIR_WORK="$(mktemp -d)"
trap "rm -rf \"$TMPDIR_WORK\"" EXIT

# --- iOS: XCFramework --------------------------------------------------------

fetch_ios() {
    if [[ -d "$IOS_FRAMEWORK_PATH" ]]; then
        # The XCFramework path has no version in it, so compare the version marker
        # to avoid keeping an outdated framework after a version bump.
        local installed_version=""
        if [[ -f "$IOS_FRAMEWORK_DIR/.iproov-version" ]]; then
            installed_version="$(cat "$IOS_FRAMEWORK_DIR/.iproov-version")"
        fi

        if [[ "$installed_version" == "$IOS_VERSION" ]]; then
            echo "[iOS] iProov.xcframework v$IOS_VERSION already exists at $IOS_FRAMEWORK_PATH — skipping."
            return
        fi

        echo "[iOS] Replacing iProov.xcframework (${installed_version:+v}${installed_version:-unknown version}) with v$IOS_VERSION..."
        rm -rf "$IOS_FRAMEWORK_PATH" "$IOS_FRAMEWORK_DIR/.iproov-version"
    fi

    echo "[iOS] Fetching iProov.xcframework v$IOS_VERSION..."

    local release_json
    release_json="$(curl_auth -s "https://api.github.com/repos/$IOS_GITHUB_REPO/releases/tags/$IOS_VERSION")"

    # We need the GitHub API (not a direct download URL) because the asset's
    # `digest` field is the only source of the iOS SHA-256 checksum.
    local asset_info
    asset_info="$(echo "$release_json" | python3 -c "
import sys, json
data = json.load(sys.stdin)
for asset in data.get('assets', []):
    if asset['name'] == 'iProov.xcframework.zip':
        print(asset['browser_download_url'])
        print(asset.get('digest', '').replace('sha256:', ''))
        break
")"

    local download_url expected_sha
    download_url="$(echo "$asset_info" | sed -n '1p')"
    expected_sha="$(echo "$asset_info" | sed -n '2p')"

    if [[ -z "$download_url" ]]; then
        echo "[iOS] ERROR: Could not find iProov.xcframework.zip in release $IOS_VERSION" >&2
        exit 1
    fi

    local zip_path="$TMPDIR_WORK/iProov.xcframework.zip"
    echo "[iOS] Downloading from $download_url..."
    curl_auth -o "$zip_path" "$download_url"

    verify_sha256 "iOS" "$zip_path" "$expected_sha"

    mkdir -p "$IOS_FRAMEWORK_DIR"
    echo "[iOS] Extracting to $IOS_FRAMEWORK_DIR..."
    unzip -q "$zip_path" -d "$IOS_FRAMEWORK_DIR"

    if [[ ! -d "$IOS_FRAMEWORK_PATH" ]]; then
        # Some zips contain a top-level directory — check one level down
        local nested
        nested="$(find "$IOS_FRAMEWORK_DIR" -maxdepth 2 -name "iProov.xcframework" -type d | head -1)"
        if [[ -n "$nested" ]]; then
            mv "$nested" "$IOS_FRAMEWORK_PATH"
        else
            echo "[iOS] ERROR: Extraction did not produce iProov.xcframework" >&2
            exit 1
        fi
    fi

    # Version marker — the verify script checks this to catch stale frameworks
    # after a version bump (the XCFramework path itself has no version in it).
    echo "$IOS_VERSION" > "$IOS_FRAMEWORK_DIR/.iproov-version"
    echo "[iOS] Done — iProov.xcframework v$IOS_VERSION installed."
}

# --- Android: AAR + POM ------------------------------------------------------

fetch_android() {
    if [[ -f "$ANDROID_AAR" && -f "$ANDROID_POM" ]]; then
        echo "[Android] AAR and POM already exist at $ANDROID_REPO_DIR — skipping."
        return
    fi

    echo "[Android] Fetching iProov AAR + POM v$ANDROID_VERSION..."

    # Download to temp first — a failed download won't leave partial files in repo/
    local tmpdir_android="$TMPDIR_WORK/android"
    mkdir -p "$tmpdir_android"

    local tmp_aar="$tmpdir_android/iproov-$ANDROID_VERSION.aar"
    local tmp_pom="$tmpdir_android/iproov-$ANDROID_VERSION.pom"

    echo "[Android] Downloading AAR..."
    curl_auth -o "$tmp_aar" "$ANDROID_MAVEN_BASE/iproov-$ANDROID_VERSION.aar"

    echo "[Android] Downloading POM..."
    curl_auth -o "$tmp_pom" "$ANDROID_MAVEN_BASE/iproov-$ANDROID_VERSION.pom"

    # Maven repos publish .sha256 files alongside artifacts for verification
    local sha_url="$ANDROID_MAVEN_BASE/iproov-$ANDROID_VERSION.aar.sha256"
    local expected_sha
    expected_sha="$(curl_auth -s "$sha_url" 2>/dev/null | awk '{print $1}' || true)"

    verify_sha256 "Android" "$tmp_aar" "$expected_sha"

    # Only place files in the final location after all checks pass
    mkdir -p "$ANDROID_REPO_DIR"
    mv "$tmp_aar" "$ANDROID_AAR"
    mv "$tmp_pom" "$ANDROID_POM"

    echo "[Android] Done — iProov AAR + POM v$ANDROID_VERSION installed."
}

# --- Main --------------------------------------------------------------------

echo "=== Fetching native SDKs for iproov_flutter ==="
echo ""
fetch_ios
echo ""
fetch_android
echo ""
echo "=== All native SDKs fetched successfully ==="
