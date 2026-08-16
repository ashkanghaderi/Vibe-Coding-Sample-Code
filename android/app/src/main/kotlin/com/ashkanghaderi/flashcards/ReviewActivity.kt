package com.ashkanghaderi.flashcards

import android.app.Activity
import android.graphics.Color
import android.os.Bundle
import android.util.TypedValue
import android.view.Gravity
import android.view.View
import android.view.ViewGroup
import android.widget.*

class ReviewActivity : Activity() {

    private var index = 0
    private var revealed = false
    private lateinit var deck: Deck
    private lateinit var root: LinearLayout

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val name = intent.getStringExtra("deck") ?: "Spanish — Verbs"
        deck = Deck.sample.firstOrNull { it.name == name } ?: Deck(name, 0)
        revealed = intent.getBooleanExtra("revealed", false)
        root = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            setPadding(dp(20), dp(24), dp(20), dp(28))
            fitsSystemWindows = true
        }
        setContentView(root)
        title = deck.name
        render()
    }

    private fun render() {
        root.removeAllViews()
        val card = deck.dueCards.getOrNull(index)
        if (card == null) {
            root.addView(TextView(this).apply {
                text = "Nothing due\nThis deck has no cards waiting for review."
                gravity = Gravity.CENTER
            })
            return
        }
        root.addView(LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            setBackgroundColor(Color.parseColor("#F2F2F7"))
            setPadding(dp(24), dp(44), dp(24), dp(44))
            layoutParams = LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT)
            addView(TextView(this@ReviewActivity).apply {
                text = card.front
                gravity = Gravity.CENTER
                setTextSize(TypedValue.COMPLEX_UNIT_SP, 34f)
                typeface = android.graphics.Typeface.DEFAULT_BOLD
            })
            if (revealed) {
                addView(TextView(this@ReviewActivity).apply {
                    text = card.back
                    gravity = Gravity.CENTER
                    setTextColor(Color.GRAY)
                    setTextSize(TypedValue.COMPLEX_UNIT_SP, 20f)
                    setPadding(0, dp(18), 0, 0)
                })
            }
            setOnClickListener { revealed = true; render() }
        })
        if (revealed) {
            root.addView(LinearLayout(this).apply {
                orientation = LinearLayout.HORIZONTAL
                setPadding(0, dp(24), 0, 0)
                addView(answerButton("Again", "#FF9500"))
                addView(answerButton("Good", "#007AFF"))
            })
        } else {
            root.addView(TextView(this).apply {
                text = "Tap the card to reveal"
                setPadding(0, dp(20), 0, 0)
                setTextColor(Color.GRAY)
            })
        }
    }

    private fun answerButton(label: String, colour: String): View =
        Button(this).apply {
            text = label
            setTextColor(Color.WHITE)
            setBackgroundColor(Color.parseColor(colour))
            layoutParams = LinearLayout.LayoutParams(0,
                ViewGroup.LayoutParams.WRAP_CONTENT, 1f).apply { setMargins(dp(6), 0, dp(6), 0) }
            setOnClickListener { revealed = false; index += 1; render() }
        }

    private fun dp(value: Int): Int = (value * resources.displayMetrics.density).toInt()
}
