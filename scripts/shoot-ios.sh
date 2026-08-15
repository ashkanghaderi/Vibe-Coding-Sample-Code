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
ROOT="$PWD"

WANTED="${1:-iPhone 17 Pro}"
BUNDLE="com.ashkanghaderi.Flashcards"
SHOTS="$ROOT/screenshots"

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
# faster than xattr can strip it. See Chapter 6.
#
# The full log goes to a file rather than the terminal. That is not tidiness:
# when a build fails, the log is the evidence, and Chapter 2 is about giving an
# assistant the log instead of letting it guess at your source.
LOG="$(mktemp -t flashcards-build)"
if ! xcodebuild -project Flashcards.xcodeproj -scheme Flashcards \
     -destination "id=$UDID" -derivedDataPath .build \
     CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO CODE_SIGN_IDENTITY="" \
     build > "$LOG" 2>&1
then
    grep -E "error:|^\*\* BUILD" "$LOG" || tail -40 "$LOG"
    echo "==> BUILD FAILED. Screenshots were NOT updated."
    echo "==> full log: $LOG"
    exit 1
fi
echo "==> build succeeded"

echo "==> launching"
xcrun simctl boot "$UDID" 2>/dev/null || true
xcrun simctl bootstatus "$UDID" -b >/dev/null
# Uninstall first, which deletes the app's container.
#
# Since Chapter 9 the app persists its decks, so without this the figures would
# show whatever previous runs happened to leave behind - the deck list would
# grow a "Portuguese" every time somebody tried the exercises. Same lesson as
# the keyboard tutorial in Chapter 8: state the screenshots depend on belongs in
# the script.
xcrun simctl uninstall "$UDID" "$BUNDLE" 2>/dev/null || true
xcrun simctl install "$UDID" .build/Build/Products/Debug-iphonesimulator/Flashcards.app

# Put the simulator into a known state before photographing it.
#
# A fresh simulator shows iOS's own keyboard tutorial ("Speed up your typing by
# sliding your finger...") the first time a text field takes focus. It appeared
# in the middle of the New Deck screenshot - a figure of somebody else's UI, in
# a book whose figures are supposed to be reproducible. The script was
# deterministic; the simulator was not.
#
# Anything the screenshots depend on belongs here, where it is visible. See
# Chapter 8.
xcrun simctl spawn "$UDID" defaults write com.apple.Preferences \
    DidShowContinuousPathIntroduction -bool true

mkdir -p "$SHOTS"

# Each screenshot is a fresh launch with launch arguments naming the screen and
# its state. The app reads them (see ScreenshotState) and opens there directly.
#
# Nobody taps anything. That is the whole point: a screenshot produced by hand
# cannot be reproduced, and a figure nobody can reproduce is a figure nobody can
# check against the code beside it.
#
# simctl resolves a relative path against its own working directory, not yours.
# `screenshots/x.png` becomes `/screenshots/x.png` and fails with "The folder
# 'x.png' doesn't exist" - a message that names the wrong thing entirely.
# Absolute paths only. See Chapter 2.
shoot() {
    local name="$1"; shift
    xcrun simctl terminate "$UDID" "$BUNDLE" 2>/dev/null || true
    xcrun simctl launch "$UDID" "$BUNDLE" "$@" >/dev/null
    sleep 3
    xcrun simctl io "$UDID" screenshot "$SHOTS/$name.png" >/dev/null 2>&1
    echo "==> wrote screenshots/$name.png"
}

shoot ios-deck-list
shoot ios-review-front   -screen review -revealed NO
shoot ios-review-back    -screen review -revealed YES
shoot ios-add-deck       -screen addDeck

# The unreadable-store screen.
#
# Corrupting the file from the script rather than adding a "pretend the store is
# broken" flag to the app: the figure then shows the real error path, not a
# simulation of it, and no book scaffolding ends up in the shipped binary.
DOCUMENTS="$(xcrun simctl get_app_container "$UDID" "$BUNDLE" data)/Documents"
mkdir -p "$DOCUMENTS"
printf '{ this is not json' > "$DOCUMENTS/decks.json"
shoot ios-load-error

# Leave the simulator in a clean state; the next run should not inherit this.
rm -f "$DOCUMENTS/decks.json" "$DOCUMENTS"/decks.corrupt-*.json
