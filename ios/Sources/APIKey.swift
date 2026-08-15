import Foundation

/// An API key that will not print itself.
///
/// The wrapper exists for one reason: `String` interpolates everywhere. A key
/// held as a String reaches logs, crash reports, analytics breadcrumbs and
/// error alerts without anybody deciding that it should - each of those is one
/// `\(key)` written by someone who was thinking about something else.
///
/// This type makes leaking it require an explicit `.rawValue`, which is a thing
/// a reviewer can search for. See Chapter 10.
struct APIKey: CustomStringConvertible, CustomDebugStringConvertible {
    private let value: String

    init?(_ value: String?) {
        // .whitespacesAndNewlines, not .whitespaces. A key read from a file or
        // an environment variable usually arrives with a trailing newline, and
        // .whitespaces does not include one - so a blank-looking key passed
        // validation, went into the Authorization header with a newline in it,
        // and came back 401. Caught by a parameterised test, not by trying it.
        let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let trimmed, !trimmed.isEmpty else { return nil }
        self.value = trimmed
    }

    /// The only way to get the key out, and the only thing to grep for.
    var rawValue: String { value }

    var description: String { "APIKey(redacted)" }
    var debugDescription: String { "APIKey(redacted)" }

    /// From the environment. There is no fallback, no default, and no key in
    /// this repository.
    static var fromEnvironment: APIKey? {
        APIKey(ProcessInfo.processInfo.environment["FLASHCARDS_API_KEY"])
    }
}
