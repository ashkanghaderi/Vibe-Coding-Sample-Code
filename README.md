# Vibe Coding iOS & Android — Sample Code

Companion code for the book **Vibe Coding iOS & Android** by Ashkan Ghaderi.

This is not a finished app dropped into a repository. **It is the build log.**
Every chapter of the book corresponds to a real commit here, made during a real
Claude Code session — including the wrong turns.

```bash
git log --oneline          # the book, as commits
git tag                    # the checkpoints chapters refer to
git checkout ch06-before   # what the model saw
git checkout ch06-after    # what fixed it
```

**This repository is being written alongside the book.** Tags appear as their
chapters are finished, so `git tag` is the authoritative list of what exists
today.

## The app

A flashcards app with AI-assisted card generation, built twice from one
specification: SwiftUI for iOS, Compose for Android. Building it twice is the
point — it separates the *practice* from the platform.

## Run it

```bash
./scripts/shoot-ios.sh
```

That generates the Xcode project, builds, boots a simulator, installs, launches,
and captures the screenshots used in the book. Every iOS screenshot in these
pages came out of that script; none was taken by hand.

## Why the Xcode project is not in here

`ios/Flashcards.xcodeproj` is generated from `ios/project.yml` by
[XcodeGen](https://github.com/yonaskolb/XcodeGen).

That is deliberate and it is a chapter. An `.xcodeproj` is effectively opaque:
you cannot review it, diff it usefully, or ask a model to reason about it. A
fourteen-line YAML file, you can. Working with AI assistance rewards making
things legible, and the project file is the first place most iOS projects fail
that test.

## Requirements

- Xcode 26.4+, XcodeGen (`brew install xcodegen`)
- Android Studio with an AVD, for Part III
- Claude Code

## License

MIT — the code. The book's text is a separate work and is not covered by it.
