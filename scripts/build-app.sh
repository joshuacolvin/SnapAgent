#!/bin/bash
set -euo pipefail

# Build SnapAgent as a proper macOS .app bundle
# Usage: ./scripts/build-app.sh

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="$PROJECT_DIR/.build"
APP_NAME="SnapAgent"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"
BUNDLE_ID="com.joshuacolvin.SnapAgent"

echo "Building $APP_NAME..."
cd "$PROJECT_DIR"
swift build -c release 2>&1

EXECUTABLE="$BUILD_DIR/release/$APP_NAME"
if [ ! -f "$EXECUTABLE" ]; then
    echo "Error: Build failed, executable not found"
    exit 1
fi

echo "Creating app bundle..."
rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

# Copy executable
cp "$EXECUTABLE" "$APP_BUNDLE/Contents/MacOS/$APP_NAME"

# Copy resources if they exist
if [ -d "$BUILD_DIR/release/SnapAgent_SnapAgent.bundle" ]; then
    cp -R "$BUILD_DIR/release/SnapAgent_SnapAgent.bundle" "$APP_BUNDLE/Contents/Resources/"
fi

# Create Info.plist
cat > "$APP_BUNDLE/Contents/Info.plist" << 'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>SnapAgent</string>
    <key>CFBundleDisplayName</key>
    <string>SnapAgent</string>
    <key>CFBundleIdentifier</key>
    <string>com.joshuacolvin.SnapAgent</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundleExecutable</key>
    <string>SnapAgent</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHumanReadableCopyright</key>
    <string>Copyright 2025 Joshua Colvin. All rights reserved.</string>
</dict>
</plist>
PLIST

echo ""
echo "Built successfully: $APP_BUNDLE"
echo ""
echo "To run:"
echo "  open $APP_BUNDLE"
echo ""
echo "To install to /Applications:"
echo "  cp -R $APP_BUNDLE /Applications/"
