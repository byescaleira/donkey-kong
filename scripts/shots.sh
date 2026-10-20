#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."

swift build --package-path ArcadeKit --product ArcadeShot
BIN="$(swift build --package-path ArcadeKit --product ArcadeShot --show-bin-path)/ArcadeShot"
mkdir -p docs/shots

render() {
  echo "--- $1 ($2) ---"
  "$BIN" --size "$2" --out "docs/shots/$1.png" "${@:3}"
}

render iphone-portrait   1179x2556
render iphone-landscape  2556x1179
render ipad              2048x2732
render mac-4k            3840x2160
render mac-5k-capped     5120x2880
render ultrawide         5120x1440
render native-no-crt     3840x2160 --upscaling off --no-crt
