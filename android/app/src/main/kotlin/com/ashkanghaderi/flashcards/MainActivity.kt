package com.ashkanghaderi.flashcards

import android.app.Activity
import android.content.Intent
import android.graphics.Color
import android.os.Bundle
import android.text.Editable
import android.text.TextWatcher
import android.util.TypedValue
import android.view.Gravity
import android.view.View
import android.view.ViewGroup
import android.widget.*

/**
 * The deck list.
 *
 * Built from framework views rather than Compose, and Chapter 15 explains why:
 * Compose could not be resolved on the machine this was written on. The layout
 * code is therefore more verbose than its SwiftUI counterpart by a factor
 * Chapter 19 measures - which turns out to be a more interesting comparison
 * than the one originally planned.
 */
class MainActivity : Activity() {

    private lateinit var store: DeckStore
    private lateinit var list: LinearLayout
    private var query = ""

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        store = DeckStore.loading(FileDeckStorage(filesDir))
        applyScreenshotState()
        setContentView(buildLayout())
        render()
    }

    /** Launch arguments, the same idea as ScreenshotState on the iOS side. */
    private fun applyScreenshotState() {
        val screen = intent.getStringExtra("screen") ?: return
        if (screen == "review") {
            val name = intent.getStringExtra("deck") ?: "Spanish — Verbs"
            val revealed = intent.getBooleanExtra("revealed", false)
            startActivity(Intent(this, ReviewActivity::class.java).apply {
                putExtra("deck", name)
                putExtra("revealed", revealed)
            })
        }
    }

    private lateinit var errorView: TextView

    private fun buildLayout(): View {
        val root = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(dp(16), dp(24), dp(16), dp(16))
            // Without this the title draws under the status bar. SwiftUI gives
            // safe areas by default; here it is opt-in, and the default is the
            // one that looks broken. Chapter 19 counts this kind of asymmetry.
            fitsSystemWindows = true
        }
        root.addView(TextView(this).apply {
            text = "Decks"
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 34f)
            typeface = android.graphics.Typeface.DEFAULT_BOLD
        })
        root.addView(EditText(this).apply {
            hint = "Search decks and cards"
            addTextChangedListener(object : TextWatcher {
                override fun afterTextChanged(s: Editable?) {
                    query = s?.toString().orEmpty(); render()
                }
                override fun beforeTextChanged(s: CharSequence?, a: Int, b: Int, c: Int) {}
                override fun onTextChanged(s: CharSequence?, a: Int, b: Int, c: Int) {}
            })
        })
        errorView = TextView(this).apply {
            setBackgroundColor(Color.parseColor("#40FF9500"))
            setPadding(dp(12), dp(12), dp(12), dp(12))
            visibility = View.GONE
        }
        root.addView(errorView)
        list = LinearLayout(this).apply { orientation = LinearLayout.VERTICAL }
        root.addView(ScrollView(this).apply { addView(list) })
        return root
    }

    private fun render() {
        store.loadError?.let {
            errorView.text = "Your decks could not be loaded. The file has been kept.\n$it"
            errorView.visibility = View.VISIBLE
        }
        list.removeAllViews()
        for (deck in DeckSearch.results(query, store.decks) { it.dueCards }) {
            list.addView(row(deck))
        }
    }

    private fun row(deck: Deck): View {
        val row = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
            setPadding(0, dp(12), 0, dp(12))
            isClickable = true
            setOnClickListener {
                startActivity(Intent(this@MainActivity, ReviewActivity::class.java)
                    .putExtra("deck", deck.name))
            }
        }
        row.addView(View(this).apply {
            setBackgroundColor(
                if (deck.dueCount > 0) Color.parseColor("#007AFF")
                else Color.parseColor("#4D8E8E93"))
            layoutParams = LinearLayout.LayoutParams(dp(4), dp(38))
        })
        row.addView(LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(dp(14), 0, 0, 0)
            layoutParams = LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f)
            addView(TextView(this@MainActivity).apply {
                text = deck.name
                setTextSize(TypedValue.COMPLEX_UNIT_SP, 17f)
            })
            addView(TextView(this@MainActivity).apply {
                text = "${deck.totalCount} cards"
                setTextSize(TypedValue.COMPLEX_UNIT_SP, 13f)
                setTextColor(Color.GRAY)
            })
        })
        if (deck.dueCount > 0) {
            row.addView(TextView(this).apply {
                text = "${deck.dueCount}"
                // Without this the badge announces the bare number. Chapter 12.
                contentDescription = "${deck.dueCount} cards due"
                setTextColor(Color.WHITE)
                gravity = Gravity.CENTER
                setPadding(dp(10), dp(4), dp(10), dp(4))
                setBackgroundColor(Color.parseColor("#007AFF"))
            })
        }
        return row
    }

    private fun dp(value: Int): Int = (value * resources.displayMetrics.density).toInt()
}
