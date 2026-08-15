---
description: Rebuild the iOS app and re-capture the book's screenshots
allowed-tools: Bash(./scripts/shoot-ios.sh:*)
argument-hint: [simulator name]
---

Run `./scripts/shoot-ios.sh $ARGUMENTS`.

If it fails, read the build log it names and report what actually failed. Do not
change any source file in response to a build failure until you have identified
the failing step from the log — the fault is often outside the code.
