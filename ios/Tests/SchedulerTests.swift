import Testing
import Foundation
@testable import Flashcards

@Suite("Scheduler")
struct SchedulerTests {

    @Test("A new card answered correctly comes back tomorrow")
    func firstCorrectAnswer() {
        let next = Scheduler.next(Scheduler.State(), grade: .good)
        #expect(next.interval == 1)
        #expect(next.streak == 1)
    }

    @Test("The second correct answer jumps to six days")
    func secondCorrectAnswer() {
        var state = Scheduler.next(Scheduler.State(), grade: .good)
        state = Scheduler.next(state, grade: .good)
        #expect(state.interval == 6)
        #expect(state.streak == 2)
    }

    @Test("After that, intervals multiply by ease")
    func thirdCorrectAnswer() {
        var state = Scheduler.State(interval: 6, ease: 2.5, streak: 2)
        state = Scheduler.next(state, grade: .good)
        #expect(state.interval == 15)          // 6 * 2.5
    }

    @Test("A wrong answer resets the streak and the interval")
    func wrongAnswerResets() {
        let state = Scheduler.State(interval: 40, ease: 2.5, streak: 6)
        let next = Scheduler.next(state, grade: .again)
        #expect(next.interval == 1)
        #expect(next.streak == 0)
    }

    @Test("A wrong answer makes the card harder, but only so far")
    func easeHasAFloor() {
        var state = Scheduler.State()
        for _ in 0..<20 {
            state = Scheduler.next(state, grade: .again)
        }
        #expect(state.ease == Scheduler.minimumEase)
    }

    @Test("Ease never drops below the floor from any starting point",
          arguments: [1.3, 1.4, 2.5, 3.0])
    func easeFloorHolds(startingEase: Double) {
        var state = Scheduler.State(ease: startingEase)
        state = Scheduler.next(state, grade: .again)
        #expect(state.ease >= Scheduler.minimumEase)
    }

    @Test("The due date is the interval in days")
    func dueDateMatchesInterval() throws {
        let day = try #require(
            Calendar.current.date(from: DateComponents(year: 2026, month: 3, day: 1))
        )
        let due = Scheduler.dueDate(for: Scheduler.State(interval: 6), from: day)
        let days = try #require(
            Calendar.current.dateComponents([.day], from: day, to: due).day
        )
        #expect(days == 6)
    }
}
