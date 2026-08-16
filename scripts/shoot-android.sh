#!/usr/bin/env bash
# Build the Android app, run it on an emulator, and capture screenshots.
#
# The counterpart to shoot-ios.sh, and deliberately the same shape: one command,
# fails loudly, sets the state it depends on rather than inheriting it, and
# writes every figure the book uses.
#
#   ./scripts/shoot-android.sh              # default AVD
#   ./scripts/shoot-android.sh Pixel_9a
set -euo pipefail
cd "$(dirname "$0")/.."
ROOT="$PWD"
SHOTS="$ROOT/screenshots"

AVD="${1:-Pixel_9a}"
PACKAGE="com.ashkanghaderi.flashcards"

export JAVA_HOME="${JAVA_HOME:-/Applications/Android Studio.app/Contents/jbr/Contents/Home}"
export ANDROID_HOME="${ANDROID_HOME:-$HOME/Library/Android/sdk}"
export PATH="$ANDROID_HOME/platform-tools:$ANDROID_HOME/emulator:$PATH"

command -v adb >/dev/null || { echo "adb not found; is ANDROID_HOME right?"; exit 1; }

if ! adb devices | grep -q "emulator.*device$"; then
    echo "==> booting $AVD"
    emulator -avd "$AVD" -no-audio -no-boot-anim -no-snapshot >/tmp/emulator.log 2>&1 &
    adb wait-for-device
    until [ "$(adb shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" = "1" ]; do
        sleep 3
    done
fi
echo "==> device: $(adb devices | awk 'NR==2{print $1}')"

echo "==> building"
LOG="$(mktemp -t flashcards-android)"
if ! (cd android && ./gradlew assembleDebug > "$LOG" 2>&1); then
    grep -E "error:|FAILURE|Could not" "$LOG" | head -20 || tail -40 "$LOG"
    echo "==> BUILD FAILED. Screenshots were NOT updated."
    echo "==> full log: $LOG"
    exit 1
fi
echo "==> build succeeded"

# State the figures depend on, set rather than assumed. Chapter 11's lesson,
# and the Android equivalents: no animations (so a screenshot is not caught
# mid-transition) and a demo status bar with a fixed clock.
adb shell settings put global window_animation_scale 0
adb shell settings put global transition_animation_scale 0
adb shell settings put global animator_duration_scale 0
adb shell settings put global sysui_demo_allowed 1
adb shell am broadcast -a com.android.systemui.demo -e command enter >/dev/null
adb shell am broadcast -a com.android.systemui.demo -e command clock -e hhmm 0941 >/dev/null
adb shell am broadcast -a com.android.systemui.demo -e command battery -e level 100 -e plugged false >/dev/null
adb shell am broadcast -a com.android.systemui.demo -e command network -e wifi show -e level 4 >/dev/null
adb shell am broadcast -a com.android.systemui.demo -e command notifications -e visible false >/dev/null

# Uninstall first: the app persists its decks, and without this the figures
# would show whatever previous runs left behind. Chapter 9.
adb uninstall "$PACKAGE" >/dev/null 2>&1 || true
adb install -r android/app/build/outputs/apk/debug/app-debug.apk >/dev/null

mkdir -p "$SHOTS"

shoot() {
    local name="$1"; shift
    adb shell am force-stop "$PACKAGE"
    adb shell am start -n "$PACKAGE/.MainActivity" "$@" >/dev/null
    sleep 3
    adb exec-out screencap -p > "$SHOTS/$name.png"
    echo "==> wrote screenshots/$name.png"
}

shoot android-deck-list
shoot android-review-front  --es screen review --ez revealed false
shoot android-review-back   --es screen review --ez revealed true

adb shell am force-stop "$PACKAGE"
