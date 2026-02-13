#!/bin/bash
set -euo pipefail

# ============================================================
# SnapAgent Release Script
# Bumps version, builds, signs, notarizes, packages DMG,
# creates GitHub release, and deploys the site.
#
# Usage: ./scripts/release.sh <version>
# Example: ./scripts/release.sh 1.1.0
# ============================================================

# --- Parse version argument ---
if [ $# -ne 1 ]; then
    echo "Usage: $0 <version>"
    echo "Example: $0 1.1.0"
    exit 1
fi

VERSION="$1"

# Strip leading 'v' if provided (e.g., v1.1.0 -> 1.1.0)
VERSION="${VERSION#v}"

if ! [[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "ERROR: Version must be in semver format (e.g., 1.1.0)"
    exit 1
fi

TAG="v$VERSION"

# --- Configuration ---
APP_NAME="SnapAgent"
SCHEME="SnapAgent"
PROJECT="SnapAgent.xcodeproj"
TEAM_ID="KHJAQ8BCGD"
BUNDLE_ID="com.joshuacolvin.SnapAgent"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$SCRIPT_DIR/.."

# Output directories
BUILD_DIR="$ROOT_DIR/build"
ARCHIVE_PATH="$BUILD_DIR/$APP_NAME.xcarchive"
EXPORT_DIR="$BUILD_DIR/export"
DMG_PATH="$BUILD_DIR/$APP_NAME.dmg"

cd "$ROOT_DIR"

echo ""
echo "============================================================"
echo "  Releasing $APP_NAME $TAG"
echo "============================================================"
echo ""

# --- Pre-flight checks ---
echo "==> Running pre-flight checks..."

if ! security find-identity -v -p codesigning | grep -q "Developer ID Application"; then
    echo "ERROR: No 'Developer ID Application' certificate found."
    echo "Install one from https://developer.apple.com/account/resources/certificates"
    exit 1
fi

if ! command -v gh &> /dev/null; then
    echo "ERROR: gh CLI not found. Install with: brew install gh"
    exit 1
fi

if ! command -v wrangler &> /dev/null; then
    echo "ERROR: wrangler CLI not found. Install with: npm install -g wrangler"
    exit 1
fi

if ! command -v create-dmg &> /dev/null; then
    echo "ERROR: create-dmg not found. Install with: brew install create-dmg"
    exit 1
fi

if [ -n "$(git status --porcelain)" ]; then
    echo "ERROR: Working directory is not clean. Commit or stash changes first."
    exit 1
fi

if git rev-parse "$TAG" > /dev/null 2>&1; then
    echo "ERROR: Tag $TAG already exists."
    exit 1
fi

echo "    All checks passed."

# --- Bump version ---
echo ""
echo "==> Bumping version to $VERSION..."

# Update Xcode project (both Debug and Release configurations)
sed -i '' "s/MARKETING_VERSION = [0-9]*\.[0-9]*\.[0-9]*/MARKETING_VERSION = $VERSION/g" "$PROJECT/project.pbxproj"

# Update landing page
sed -i '' "s/v[0-9]*\.[0-9]*\.[0-9]*/v$VERSION/g" docs/index.html

echo "    Updated $PROJECT/project.pbxproj"
echo "    Updated docs/index.html"

# --- Clean build directory ---
echo ""
echo "==> Cleaning build directory..."
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

# --- Archive ---
echo ""
echo "==> Archiving $APP_NAME..."
xcodebuild archive \
    -project "$PROJECT" \
    -scheme "$SCHEME" \
    -configuration Release \
    -destination "generic/platform=macOS" \
    -archivePath "$ARCHIVE_PATH" \
    | tail -5

echo "    Archive created at $ARCHIVE_PATH"

# --- Export ---
echo ""
echo "==> Exporting app..."
cat > "$BUILD_DIR/ExportOptions.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>developer-id</string>
    <key>teamID</key>
    <string>$TEAM_ID</string>
    <key>signingStyle</key>
    <string>automatic</string>
</dict>
</plist>
PLIST

xcodebuild -exportArchive \
    -archivePath "$ARCHIVE_PATH" \
    -exportPath "$EXPORT_DIR" \
    -exportOptionsPlist "$BUILD_DIR/ExportOptions.plist" \
    | tail -5

APP_PATH="$EXPORT_DIR/$APP_NAME.app"
echo "    Exported to $APP_PATH"

# --- Notarize ---
KEYCHAIN_PROFILE="SnapAgent"

echo ""
echo "==> Notarizing $APP_NAME..."

if ! xcrun notarytool history --keychain-profile "$KEYCHAIN_PROFILE" > /dev/null 2>&1; then
    echo ""
    echo "ERROR: No keychain profile '$KEYCHAIN_PROFILE' found."
    echo ""
    echo "Set it up once with:"
    echo "  xcrun notarytool store-credentials \"$KEYCHAIN_PROFILE\" \\"
    echo "    --apple-id \"your@email.com\" \\"
    echo "    --team-id \"$TEAM_ID\" \\"
    echo "    --password \"your-app-specific-password\""
    exit 1
fi

echo "    Creating zip for notarization..."
ditto -c -k --keepParent "$APP_PATH" "$BUILD_DIR/$APP_NAME.zip"

echo "    Submitting to Apple..."
xcrun notarytool submit "$BUILD_DIR/$APP_NAME.zip" \
    --keychain-profile "$KEYCHAIN_PROFILE" \
    --wait

echo "    Stapling notarization ticket..."
xcrun stapler staple "$APP_PATH"

# --- Create styled DMG ---
echo ""
echo "==> Creating DMG..."
python3 "$SCRIPT_DIR/create-dmg-bg.py"

rm -f "$DMG_PATH"
create-dmg \
    --volname "$APP_NAME" \
    --background "$BUILD_DIR/dmg-background.png" \
    --window-pos 200 120 \
    --window-size 660 400 \
    --icon-size 128 \
    --icon "$APP_NAME.app" 170 190 \
    --app-drop-link 490 190 \
    --no-internet-enable \
    "$DMG_PATH" \
    "$APP_PATH"

echo "    DMG created at $DMG_PATH"

# --- Commit, tag, and push ---
echo ""
echo "==> Committing version bump and pushing..."
git add "$PROJECT/project.pbxproj" docs/index.html
git commit -m "Bump version to $VERSION"
git tag "$TAG"
git push origin main
git push origin "$TAG"

# --- GitHub Release ---
echo ""
echo "==> Creating GitHub release $TAG..."
gh release create "$TAG" "$DMG_PATH" \
    --title "$APP_NAME $TAG" \
    --notes "## $APP_NAME $TAG

Download **$APP_NAME.dmg** below to install.

Requires macOS 13+. Supports Apple Silicon and Intel."

echo "    Release created: $(gh release view "$TAG" --json url -q .url)"

# --- Deploy site ---
echo ""
echo "==> Deploying site to Cloudflare Pages..."
wrangler pages deploy docs --project-name snapagent --branch main

echo ""
echo "============================================================"
echo "  Released $APP_NAME $TAG"
echo ""
echo "  DMG:     $DMG_PATH"
echo "  Release: https://github.com/joshuacolvin/SnapAgent/releases/tag/$TAG"
echo "  Site:    https://snapagent.baxlylabs.com"
echo "============================================================"
