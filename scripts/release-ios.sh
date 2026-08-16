#!/usr/bin/env bash
# Archive the app and export it for App Store Connect.
#
# This script stops before uploading. Uploading is the one step in this
# repository that other people can see, so it is a decision a person makes, not
# a thing a script does at the end of a build. See Chapter 14.
#
#   FLASHCARDS_TEAM_ID=ABCDE12345 ./scripts/release-ios.sh
set -euo pipefail
cd "$(dirname "$0")/.."

: "${FLASHCARDS_TEAM_ID:?set FLASHCARDS_TEAM_ID to your Apple Developer team ID}"

ARCHIVE="build/Flashcards.xcarchive"
EXPORT="build/export"

cd ios
xcodegen generate >/dev/null

echo "==> archiving"
LOG="$(mktemp -t flashcards-archive)"
if ! xcodebuild archive \
     -project Flashcards.xcodeproj -scheme Flashcards \
     -destination "generic/platform=iOS" \
     -archivePath "../$ARCHIVE" \
     DEVELOPMENT_TEAM="$FLASHCARDS_TEAM_ID" \
     > "$LOG" 2>&1
then
    grep -E "error:|^\*\* ARCHIVE" "$LOG" | head -20 || tail -40 "$LOG"
    echo "==> ARCHIVE FAILED"
    echo "==> full log: $LOG"
    exit 1
fi
echo "==> archived"

cd ..
cat > build/ExportOptions.plist <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>method</key><string>app-store-connect</string>
  <key>destination</key><string>export</string>
  <key>signingStyle</key><string>automatic</string>
  <key>teamID</key><string>$FLASHCARDS_TEAM_ID</string>
  <key>uploadSymbols</key><true/>
</dict>
</plist>
PLIST

echo "==> exporting"
rm -rf "$EXPORT"
xcodebuild -exportArchive \
    -archivePath "$ARCHIVE" \
    -exportOptionsPlist build/ExportOptions.plist \
    -exportPath "$EXPORT"

echo
echo "==> wrote $EXPORT"
ls -la "$EXPORT"
echo
echo "Nothing has been uploaded. To ship it:"
echo "  xcrun altool --upload-app -f $EXPORT/Flashcards.ipa \\"
echo "    --type ios --apiKey <KEY_ID> --apiIssuer <ISSUER_ID>"
echo
echo "Run that yourself, when you have decided to. See Chapter 14."
