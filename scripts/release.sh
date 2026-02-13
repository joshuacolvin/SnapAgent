#!/bin/bash
set -euo pipefail

# ============================================================
# SnapAgent Release Script
# Builds, signs, notarizes, and packages SnapAgent for distribution
# ============================================================

# --- Configuration ---
APP_NAME="SnapAgent"
SCHEME="SnapAgent"
PROJECT="SnapAgent.xcodeproj"
TEAM_ID="KHJAQ8BCGD"
BUNDLE_ID="com.joshuacolvin.SnapAgent"

# Output directories
BUILD_DIR="$(pwd)/build"
ARCHIVE_PATH="$BUILD_DIR/$APP_NAME.xcarchive"
EXPORT_DIR="$BUILD_DIR/export"
DMG_PATH="$BUILD_DIR/$APP_NAME.dmg"

# --- Pre-flight checks ---
echo "==> Checking for Developer ID certificate..."
if ! security find-identity -v -p codesigning | grep -q "Developer ID Application"; then
    echo "ERROR: No 'Developer ID Application' certificate found."
    echo "Install one from https://developer.apple.com/account/resources/certificates"
    exit 1
fi

# --- Clean build directory ---
echo "==> Cleaning build directory..."
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

# --- Archive ---
echo "==> Archiving $APP_NAME..."
xcodebuild archive \
    -project "$PROJECT" \
    -scheme "$SCHEME" \
    -configuration Release \
    -destination "generic/platform=macOS" \
    -archivePath "$ARCHIVE_PATH" \
    | tail -5

echo "==> Archive created at $ARCHIVE_PATH"

# --- Export ---
echo "==> Creating export options..."
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

echo "==> Exporting app..."
xcodebuild -exportArchive \
    -archivePath "$ARCHIVE_PATH" \
    -exportPath "$EXPORT_DIR" \
    -exportOptionsPlist "$BUILD_DIR/ExportOptions.plist" \
    | tail -5

APP_PATH="$EXPORT_DIR/$APP_NAME.app"
echo "==> Exported to $APP_PATH"

# --- Notarize ---
# --- Notarize ---
KEYCHAIN_PROFILE="SnapAgent"

echo ""
echo "==> Notarizing $APP_NAME..."

# Check if keychain profile exists
if ! xcrun notarytool history --keychain-profile "$KEYCHAIN_PROFILE" > /dev/null 2>&1; then
    echo ""
    echo "ERROR: No keychain profile '$KEYCHAIN_PROFILE' found."
    echo ""
    echo "Set it up once with:"
    echo "  xcrun notarytool store-credentials \"$KEYCHAIN_PROFILE\" \\"
    echo "    --apple-id \"your@email.com\" \\"
    echo "    --team-id \"$TEAM_ID\" \\"
    echo "    --password \"your-app-specific-password\""
    echo ""
    echo "Skipping notarization. App is at: $APP_PATH"
    exit 0
fi

# Create zip for notarization
echo "==> Creating zip for notarization..."
ditto -c -k --keepParent "$APP_PATH" "$BUILD_DIR/$APP_NAME.zip"

# Submit for notarization
echo "==> Submitting to Apple..."
xcrun notarytool submit "$BUILD_DIR/$APP_NAME.zip" \
    --keychain-profile "$KEYCHAIN_PROFILE" \
    --wait

# Staple the ticket
echo "==> Stapling notarization ticket..."
xcrun stapler staple "$APP_PATH"

# --- Create styled DMG ---
echo "==> Generating DMG background..."
python3 "$(dirname "$0")/create-dmg-bg.py"

echo "==> Creating DMG..."
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

echo ""
echo "============================================================"
echo "  Done! Distribute this file:"
echo "  $DMG_PATH"
echo "============================================================"
