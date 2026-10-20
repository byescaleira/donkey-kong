#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
xcodebuild -project ScrapSpire/ScrapSpire.xcodeproj -scheme ScrapSpire \
  -destination 'platform=macOS' -configuration Debug build > /dev/null
APP=$(find ~/Library/Developer/Xcode/DerivedData -name "Scrap Spire.app" \
  -path "*Debug/*" -maxdepth 6 2>/dev/null | head -1)
echo "launching $APP"
open "$APP"
