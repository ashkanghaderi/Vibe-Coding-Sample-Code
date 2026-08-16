package com.ashkanghaderi.flashcards

/**
 * When a card should next be shown.
 *
 * A direct port of Scheduler.swift, deliberately. Chapter 19 compares the two
 * line by line; keeping them parallel is what makes that comparison mean
 * anything.
 *
 * Nothing here imports android.*, which is what lets the tests run on a plain
 * JVM in milliseconds. Same reasoning as the iOS side: logic apart from screen.
 */
object Scheduler {

    enum class Grade { AGAIN, GOOD }

    data class State(
        val interval: Int = 0,
        val ease: Double = 2.5,
        val streak: Int = 0,
    )

    const val MINIMUM_EASE = 1.3

    fun next(state: State, grade: Grade): State = when (grade) {
        Grade.AGAIN -> state.copy(
            interval = 1,
            ease = maxOf(MINIMUM_EASE, state.ease - 0.2),
            streak = 0,
        )
        Grade.GOOD -> {
            val streak = state.streak + 1
            state.copy(
                interval = when (streak) {
                    1 -> 1
                    2 -> 6
                    else -> Math.round(state.interval * state.ease).toInt()
                },
                streak = streak,
            )
        }
    }
}
