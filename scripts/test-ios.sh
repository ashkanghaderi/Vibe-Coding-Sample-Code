#!/usr/bin/env bash
# Run the iOS unit tests on a simulator.
#
#   ./scripts/test-ios.sh
#   ./scripts/test-ios.sh "iPhone 17 Pro"
set -euo pipefail
cd "$(dirname "$0")/.."

WANTED="${1:-iPhone 17 Pro}"

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

LOG="$(mktemp -t flashcards-test)"
if ! xcodebuild test -project Flashcards.xcodeproj -scheme Flashcards \
     -destination "id=$UDID" -derivedDataPath .build \
     CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO CODE_SIGN_IDENTITY="" \
     > "$LOG" 2>&1
then
    grep -E "error:|failed|✘|Test Case.*failed" "$LOG" | head -40 || tail -40 "$LOG"
    echo "==> TESTS FAILED"
    echo "==> full log: $LOG"
    exit 1
fi

# Report the Swift Testing summary, and *not* xcodebuild's XCTest one.
#
# With seven Swift Testing tests passing, the XCTest summary still reads
# "Executed 0 tests, with 0 failures" - it is counting a framework we do not
# use. It prints exactly the same line when there are no tests at all, so a
# script that quotes it as evidence is quoting nothing. See Chapter 5.
SUMMARY=$(grep -E "Test run with .* (passed|failed)" "$LOG" | tail -1 || true)

# No summary means no tests ran. xcodebuild is perfectly happy about that - a
# test target with nothing in it exits 0 and says nothing at all, which is the
# one outcome that must never read as success. See Chapter 5.
if [ -z "$SUMMARY" ]; then
    echo "==> NO TESTS RAN. The target built and executed nothing."
    echo "==> full log: $LOG"
    exit 1
fi

echo "$SUMMARY"
echo "==> tests passed"
