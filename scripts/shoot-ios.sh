#!/usr/bin/env bash
# Build the iOS app, run it on a simulator, and capture screenshots.
#
# Every iOS screenshot in this book is produced by this script. None is taken by
# hand, so none can show an older version of the app than the code beside it.
#
#   ./scripts/shoot-ios.sh                 # default device
#   ./scripts/shoot-ios.sh "iPhone 17 Pro"
set -euo pipefail
cd "$(dirname "$0")/.."

WANTED="${1:-iPhone 17 Pro}"
BUNDLE="com.ashkanghaderi.Flashcards"

UDID=$(xcrun simctl list devices available -j | python3 -c "
import json,sys
want='''$WANTED'''
d=json.load(sys.stdin)['devices']
for rt in sorted(d, reverse=True):
    for dev in d[rt]:
        if dev['name'] == want: print(dev['udid']); raise SystemExit
raise SystemExit('no simulator named ' + want)
")
echo "==> device: $WANTED ($UDID)"

cd ios
xcodegen generate >/dev/null
echo "==> building"
# Simulator builds need no signature, and skipping it avoids a codesign failure
# on machines where the system stamps com.apple.provenance onto build products
# faster than xattr can strip it. See Chapter 3.
xcodebuild -project Flashcards.xcodeproj -scheme Flashcards \
  -destination "id=$UDID" -derivedDataPath .build \
  CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO CODE_SIGN_IDENTITY="" \
  build 2>&1 | grep -E "^\*\*|error:" || true

echo "==> launching"
xcrun simctl boot "$UDID" 2>/dev/null || true
xcrun simctl bootstatus "$UDID" -b >/dev/null
xcrun simctl install "$UDID" .build/Build/Products/Debug-iphonesimulator/Flashcards.app
xcrun simctl launch "$UDID" "$BUNDLE" >/dev/null
sleep 4

cd ..
mkdir -p screenshots
xcrun simctl io "$UDID" screenshot screenshots/ios-deck-list.png 2>/dev/null
echo "==> wrote screenshots/ios-deck-list.png"
