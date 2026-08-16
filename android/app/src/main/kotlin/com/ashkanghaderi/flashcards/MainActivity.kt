package com.ashkanghaderi.flashcards

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent {
            MaterialTheme { DeckListScreen(Deck.sample) }
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun DeckListScreen(decks: List<Deck>) {
    Scaffold(
        topBar = { LargeTopAppBar(title = { Text("Decks") }) }
    ) { padding ->
        LazyColumn(
            modifier = Modifier.padding(padding).fillMaxSize(),
            contentPadding = PaddingValues(horizontal = 16.dp, vertical = 8.dp),
        ) {
            items(decks) { deck -> DeckRow(deck) }
        }
    }
}

@Composable
private fun DeckRow(deck: Deck) {
    Row(
        verticalAlignment = Alignment.CenterVertically,
        modifier = Modifier.fillMaxWidth().padding(vertical = 12.dp),
    ) {
        Box(
            Modifier
                .width(4.dp)
                .height(38.dp)
                .clip(RoundedCornerShape(2.dp))
                .background(
                    if (deck.dueCount > 0) MaterialTheme.colorScheme.primary
                    else Color.Gray.copy(alpha = 0.3f)
                )
        )
        Spacer(Modifier.width(14.dp))
        Column(Modifier.weight(1f)) {
            Text(deck.name, style = MaterialTheme.typography.bodyLarge,
                 fontWeight = FontWeight.Medium)
            Text("${deck.totalCount} cards",
                 style = MaterialTheme.typography.bodySmall,
                 color = MaterialTheme.colorScheme.onSurfaceVariant)
        }
        if (deck.dueCount > 0) {
            Badge(containerColor = MaterialTheme.colorScheme.primary) {
                Text("${deck.dueCount}")
            }
        }
    }
}
