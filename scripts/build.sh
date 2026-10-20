#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."

CONFIG="${1:-Debug}"
PROJECT="ScrapSpire/ScrapSpire.xcodeproj"
# Local builds have no signing identity. Xcode Cloud signs for real, so this
# stays on the command line and never in the project.
NOSIGN=(CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO)

echo "==> Swift package"
swift build --package-path ArcadeKit

echo "==> macOS ($CONFIG)"
xcodebuild -project "$PROJECT" -scheme ScrapSpire \
  -destination 'platform=macOS' -configuration "$CONFIG" "${NOSIGN[@]}" build | \
  grep -E "error:|warning:|BUILD" || true

echo "==> tvOS Simulator ($CONFIG)"
xcodebuild -project "$PROJECT" -scheme ScrapSpire \
  -destination 'platform=tvOS Simulator,name=Apple TV 4K (3rd generation)' -configuration "$CONFIG" "${NOSIGN[@]}" build | \
  grep -E "error:|warning:|BUILD" || true

echo "==> iOS Simulator ($CONFIG)"
xcodebuild -project "$PROJECT" -scheme ScrapSpire \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -configuration "$CONFIG" "${NOSIGN[@]}" build | \
  grep -E "error:|warning:|BUILD" || true
