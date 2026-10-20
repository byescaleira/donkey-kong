#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."

CONFIG="${1:-Debug}"
PROJECT="ScrapSpire/ScrapSpire.xcodeproj"

echo "==> Swift package"
swift build --package-path ArcadeKit

echo "==> macOS ($CONFIG)"
xcodebuild -project "$PROJECT" -scheme ScrapSpire \
  -destination 'platform=macOS' -configuration "$CONFIG" build | \
  grep -E "error:|warning:|BUILD" || true

echo "==> iOS Simulator ($CONFIG)"
xcodebuild -project "$PROJECT" -scheme ScrapSpire \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -configuration "$CONFIG" build | \
  grep -E "error:|warning:|BUILD" || true
