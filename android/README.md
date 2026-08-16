# Android — work in progress

This directory does not build yet in the environment it was written in, and the
reason is worth recording rather than hiding.

`https://dl.google.com/dl/android/maven2` returns HTTP 404 for every artifact
requested from it here, including ones that are certainly published — for
example `androidx.activity:activity-compose:1.9.3`, which is present in the
local Gradle cache and therefore definitely exists. Maven Central responds
normally (`junit:junit:4.13.2` resolves), so this is specific to Google's Maven
repository, not to networking in general.

The local Gradle cache is partial: some artifacts are complete, and some
directories exist with no files in them, which is why `--offline` also fails
with "No cached version of androidx.annotation:annotation-jvm:1.8.1 available".

What is verified:

- JDK 21 (Android Studio's bundled JBR) and Gradle 8.14.5 both work
- `gradle wrapper` succeeds, and the generated wrapper runs
- AGP 8.13.2, Kotlin 2.0.21 and the Compose compiler plugin all resolve
- The build reaches `:app:checkDebugAarMetadata`, so the project itself is
  well-formed — it fails on dependency download, not on configuration

To finish it, run one build with access to Google's Maven:

    JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home" \
    ANDROID_HOME="$HOME/Library/Android/sdk" \
    ./gradlew assembleDebug

Once the cache is populated, `--offline` will work from here.
