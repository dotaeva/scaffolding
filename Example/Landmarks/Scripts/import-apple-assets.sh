#!/bin/sh
# Replaces the generated placeholder art with the real photographs from a
# local copy of Apple's "Landmarks: Building an app with Liquid Glass"
# sample: https://developer.apple.com/documentation/swiftui/landmarks-building-an-app-with-liquid-glass
#
# Apple's sample-code license does NOT cover the photographs, so they must
# not be committed or redistributed. This writes them into your working
# copy only — run Scripts/generate-placeholder-assets.py before committing
# to put the placeholder art back.
#
# Photos are downscaled on import (backgrounds 2000px, thumbnails 900px),
# which keeps the working copy at ~20 MB instead of ~160 MB. Pass
# --full-size to copy them untouched.
set -eu
SAMPLE="${1:?usage: import-apple-assets.sh /path/to/LandmarksBuildingAnAppWithLiquidGlass [--full-size]}"
FULL="${2:-}"
SRC="$SAMPLE/Landmarks/Landmarks/Resources/Assets.xcassets"
DST="$(cd "$(dirname "$0")/.." && pwd)/Sources/Resources/Assets.xcassets"
[ -d "$SRC" ] || { echo "No asset catalog at $SRC" >&2; exit 1; }

rm -rf "$DST"
cp -R "$SRC" "$DST"

if [ "$FULL" != "--full-size" ]; then
  find "$DST/Landmark backgrounds" -name "*.jpg" -exec sips -Z 2000 {} --out {} >/dev/null \;
  find "$DST/Landmark thumbnails" -name "*.jpg" -exec sips -Z 900 {} --out {} >/dev/null \;
fi

echo "Imported Apple's photographs into $DST"
echo "Do NOT commit them — run Scripts/generate-placeholder-assets.py to restore placeholders."
