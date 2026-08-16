package com.ashkanghaderi.flashcards

import java.io.File

class StorageException(message: String) : Exception(message)

/**
 * Reading and writing the deck list.
 *
 * The encoding is written by hand rather than pulled from a library, and that
 * is not principle - it is Chapter 15's constraint made into a decision. This
 * machine could not reach Google's Maven, so org.json (which is stubbed in unit
 * tests anyway) and kotlinx.serialization were both unavailable. Forty lines of
 * hand-rolled encoding runs on a plain JVM, needs nothing, and is the only code
 * here that the iOS side gets for free from Codable.
 *
 * That asymmetry is a real finding, and Chapter 19 counts it.
 */
interface DeckStorage {
    fun load(): List<Deck>
    fun save(decks: List<Deck>)
}

class FileDeckStorage(directory: File) : DeckStorage {
    val file = File(directory, "decks.json")

    override fun load(): List<Deck> {
        if (!file.exists()) return Deck.sample           // first run
        val text = file.readText()
        return try {
            decode(text)
        } catch (error: Exception) {
            // Chapter 9, in Kotlin: an unreadable file is somebody's data.
            // Preserve it, and do not return an empty list that the next save
            // would write over.
            runCatching {
                file.renameTo(File(file.parentFile, "decks.corrupt-${System.currentTimeMillis()}.json"))
            }
            throw StorageException("Could not read decks: ${error.message}")
        }
    }

    override fun save(decks: List<Deck>) {
        file.parentFile?.mkdirs()
        // Atomic: write beside it, then rename. A crash leaves the old file
        // rather than half of the new one.
        val temporary = File(file.parentFile, "decks.json.tmp")
        temporary.writeText(encode(decks))
        if (!temporary.renameTo(file)) {
            temporary.delete()
            throw StorageException("Could not replace ${file.name}")
        }
    }

    companion object {
        fun encode(decks: List<Deck>): String =
            decks.joinToString(",", "[", "]") {
                """{"name":${quote(it.name)},"totalCount":${it.totalCount}}"""
            }

        fun decode(text: String): List<Deck> {
            val trimmed = text.trim()
            require(trimmed.startsWith("[") && trimmed.endsWith("]")) { "not a list" }
            val body = trimmed.substring(1, trimmed.length - 1).trim()
            if (body.isEmpty()) return emptyList()
            return Regex("""\{[^}]*\}""").findAll(body).map { match ->
                val obj = match.value
                val name = Regex(""""name"\s*:\s*"((?:[^"\\]|\\.)*)"""")
                    .find(obj)?.groupValues?.get(1)
                    ?: throw IllegalArgumentException("deck with no name")
                val count = Regex(""""totalCount"\s*:\s*(-?\d+)""")
                    .find(obj)?.groupValues?.get(1)?.toInt()
                    ?: throw IllegalArgumentException("deck with no totalCount")
                Deck(unquote(name), count)
            }.toList().ifEmpty { throw IllegalArgumentException("no decks in a non-empty list") }
        }

        private fun quote(value: String) =
            "\"" + value.replace("\\", "\\\\").replace("\"", "\\\"") + "\""

        private fun unquote(value: String) =
            value.replace("\\\"", "\"").replace("\\\\", "\\")
    }
}
