import Foundation

/// When a card should next be shown.
///
/// This is the part of the app that has a right answer. It takes numbers and
/// returns numbers, touches nothing, and can be checked exactly — which is why
/// it lives in its own file with no import of SwiftUI. Chapter 5 is about the
/// difference between code like this and code you can only look at.
enum Scheduler {

    /// How the learner answered.
    enum Grade {
        case again      // got it wrong
        case good       // got it right
    }

    /// What the app remembers about a card between reviews.
    struct State: Equatable {
        /// Days until the next review.
        var interval: Int = 0
        /// How much the interval grows on a correct answer.
        var ease: Double = 2.5
        /// Consecutive correct answers.
        var streak: Int = 0
    }

    static let minimumEase = 1.3

    /// The state a card should be in after being answered.
    static func next(_ state: State, grade: Grade) -> State {
        var next = state

        switch grade {
        case .again:
            next.streak = 0
            next.interval = 1
            next.ease = max(minimumEase, state.ease - 0.2)

        case .good:
            next.streak = state.streak + 1
            next.ease = state.ease
            next.interval = switch next.streak {
            case 1: 1
            case 2: 6
            default: Int((Double(state.interval) * state.ease).rounded())
            }
        }

        return next
    }

    /// The date a card in this state is next due, from a given day.
    static func dueDate(for state: State, from day: Date) -> Date {
        Calendar.current.date(byAdding: .day, value: state.interval, to: day) ?? day
    }
}
