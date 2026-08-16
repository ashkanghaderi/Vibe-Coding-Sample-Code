# Android

The same app, from the same specification, in Kotlin.

    ./scripts/shoot-android.sh          # build, boot an emulator, capture
    cd android && ./gradlew testDebugUnitTest

## Why there is no Compose here

Compose is not used, and the reason is a constraint rather than a preference.

On the machine this was written on, `https://dl.google.com/dl/android/maven2`
returns HTTP 404 for every artifact requested from it — including ones that are
certainly published, and including the group index. Maven Central answers
normally. The local Gradle cache holds Compose *metadata* (`.pom`, `.module`)
but none of the `.aar` files, so `--offline` cannot help either.

So this app is built from the Android framework's own views, with no androidx
dependency at all. `android.useAndroidX=false`, and the only external
dependency is JUnit, from Maven Central.

That turned out to be more interesting than the original plan. Chapter 19
compares SwiftUI against framework views rather than against Compose, which
makes the asymmetries larger and easier to see — safe areas, list construction,
and the forty lines of hand-written JSON that `Codable` gives the iOS side for
free.

If you have access to Google's Maven, adding Compose back is a plugin, a BOM
and a dependency block. The logic layer would not change at all, which is
itself the point of Part III.
