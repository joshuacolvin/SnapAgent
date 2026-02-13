# SnapAgent

A lightweight macOS menu bar app that captures screenshots and injects file paths directly into your terminal. Built for developers who work with AI coding tools.

**Website:** [snapagent.baxlylabs.com](https://snapagent.baxlylabs.com)

## What it does

1. Hit a hotkey to capture a screenshot (region or full screen)
2. SnapAgent saves it to `~/.ai-screenshots/` — not your Desktop
3. The file path is automatically pasted into your last active terminal
4. Old screenshots are auto-cleaned so they don't pile up

## Requirements

- macOS 13+
- Apple Silicon or Intel

## Supported terminals

Terminal, iTerm2, Warp, Ghostty, VS Code, Cursor, Kitty, Alacritty, Hyper, WezTerm

## Development

Built with Swift/SwiftUI using Swift Package Manager.

```bash
open SnapAgent.xcodeproj
```

## Scripts

| Script | Description |
|---|---|
| `scripts/release.sh` | Build, sign, notarize, and package the DMG for distribution |
| `scripts/deploy-site.sh` | Deploy the landing page to Cloudflare Pages |
| `scripts/build-app.sh` | Build the app locally |
| `scripts/create-dmg-bg.py` | Generate the DMG background image |

## Releasing a new version

1. Bump the version in Xcode (MARKETING_VERSION in project settings)
2. Run the release script to build the DMG:
   ```bash
   ./scripts/release.sh
   ```
3. Create a GitHub release with the DMG:
   ```bash
   gh release create v1.x.x build/SnapAgent.dmg --title "SnapAgent v1.x.x" --notes "Release notes here"
   ```
4. Update the version number in `docs/index.html` if needed
5. Deploy the site:
   ```bash
   ./scripts/deploy-site.sh
   ```

The download links on the site point to `/releases/latest/download/SnapAgent.dmg`, so they automatically serve the newest release.
