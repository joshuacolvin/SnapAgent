#!/bin/bash
set -euo pipefail

# ============================================================
# SnapAgent Cleanup Script
# Removes app, settings, container, and screenshots for a
# clean reinstall.
#
# Usage: ./scripts/cleanup.sh
# ============================================================

APP_NAME="SnapAgent"
BUNDLE_ID="com.joshuacolvin.SnapAgent"

echo ""
echo "============================================================"
echo "  $APP_NAME Cleanup"
echo "============================================================"
echo ""

# Quit the app if running
if pgrep -xq "$APP_NAME"; then
    echo "==> Quitting $APP_NAME..."
    osascript -e "quit app \"$APP_NAME\"" 2>/dev/null || true
    sleep 1
fi

# Remove the app
if [ -d "/Applications/$APP_NAME.app" ]; then
    echo "==> Removing /Applications/$APP_NAME.app"
    rm -rf "/Applications/$APP_NAME.app"
else
    echo "==> /Applications/$APP_NAME.app not found, skipping"
fi

# Delete UserDefaults
if defaults read "$BUNDLE_ID" &>/dev/null; then
    echo "==> Deleting UserDefaults for $BUNDLE_ID"
    defaults delete "$BUNDLE_ID"
else
    echo "==> No UserDefaults found, skipping"
fi

# Remove app container
if [ -d "$HOME/Library/Containers/$BUNDLE_ID" ]; then
    echo "==> Removing app container"
    rm -rf "$HOME/Library/Containers/$BUNDLE_ID"
else
    echo "==> No app container found, skipping"
fi

# Remove screenshots
if [ -d "$HOME/.ai-screenshots" ]; then
    echo "==> Removing screenshots (~/.ai-screenshots)"
    rm -rf "$HOME/.ai-screenshots"
else
    echo "==> No screenshots directory found, skipping"
fi

echo ""
echo "  Cleanup complete."
echo ""

# Prompt to reset system permissions
echo "==> To also reset macOS system permissions (Screen Recording,"
echo "    Accessibility), run the following commands:"
echo ""
echo "    tccutil reset ScreenCapture $BUNDLE_ID"
echo "    tccutil reset Accessibility $BUNDLE_ID"
echo ""
read -rp "    Run these now? [y/N] " answer
if [[ "$answer" =~ ^[Yy]$ ]]; then
    echo ""
    echo "==> Resetting Screen Recording permission..."
    tccutil reset ScreenCapture "$BUNDLE_ID"
    echo "==> Resetting Accessibility permission..."
    tccutil reset Accessibility "$BUNDLE_ID"
    echo ""
    echo "  System permissions reset."
fi

echo ""
echo "  Ready for a fresh install."
echo ""
