package com.aktasilyas.elyanotes

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.provider.OpenableColumns
import android.system.ErrnoException
import android.system.OsConstants
import android.util.Log
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.util.concurrent.Executors

/**
 * Receives PDFs from "Open with" (ACTION_VIEW) and "Share" (ACTION_SEND), #200.
 *
 * The content URI is copied into cacheDir/incoming on a background thread and
 * handed to Dart over the `elyanotes/incoming_pdf` channel as
 * {path, name, size} (`onPdf`). Dart imports it into app storage and deletes
 * the copy, so no persistable URI permission is needed. A PDF that cannot be
 * copied is reported as {name, reason: storageFull|unreadable} (`onPdfError`).
 * Items received before Dart is listening (cold start) are buffered until Dart
 * calls `ready`, which returns both kinds; failures carry the `reason` key.
 */
class MainActivity : FlutterFragmentActivity() {
    private val executor = Executors.newSingleThreadExecutor()
    private val mainHandler = Handler(Looper.getMainLooper())
    private val pending = mutableListOf<Pending>()
    private var channel: MethodChannel? = null
    private var dartReady = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        channel =
            MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).apply {
                setMethodCallHandler { call, result ->
                    if (call.method == "ready") {
                        dartReady = true
                        result.success(pending.map { it.payload })
                        pending.clear()
                    } else {
                        result.notImplemented()
                    }
                }
            }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Not on recreation (rotation) or relaunch from Recents: the PDF was
        // already delivered by the original launch.
        val fromHistory = (intent.flags and Intent.FLAG_ACTIVITY_LAUNCHED_FROM_HISTORY) != 0
        if (savedInstanceState == null && !fromHistory) handleIntent(intent)
        executor.execute(::deleteStaleCopies)
    }

    /** Copies left behind when the process died before Dart imported them. */
    private fun deleteStaleCopies() {
        val cutoff = System.currentTimeMillis() - STALE_AFTER_MS
        File(cacheDir, INCOMING_DIR).listFiles()?.forEach {
            if (it.lastModified() < cutoff) it.delete()
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleIntent(intent)
    }

    override fun onDestroy() {
        channel?.setMethodCallHandler(null)
        channel = null
        dartReady = false
        executor.shutdown()
        super.onDestroy()
    }

    private fun handleIntent(intent: Intent?) {
        val uri = pdfUri(intent) ?: return
        executor.execute {
            val item =
                try {
                    Pending(ON_PDF, copyToCache(uri))
                } catch (e: Exception) {
                    Log.w(TAG, "Could not read incoming PDF", e)
                    val reason = if (isStorageFull(e)) "storageFull" else "unreadable"
                    Pending(ON_PDF_ERROR, mapOf("name" to safeName(uri), "reason" to reason))
                }
            mainHandler.post { deliver(item) }
        }
    }

    /** True when [e] or one of its causes is ENOSPC (disk full during copy). */
    private fun isStorageFull(e: Throwable): Boolean =
        generateSequence(e) { it.cause }.take(MAX_CAUSE_DEPTH).any {
            (it is ErrnoException && it.errno == OsConstants.ENOSPC) ||
                it.message?.contains("ENOSPC") == true
        }

    /** The display name, if the provider still answers; for error messages. */
    private fun safeName(uri: Uri): String =
        runCatching { displayName(uri) }.getOrNull()?.takeIf { it.isNotBlank() }
            ?: DEFAULT_NAME

    private fun pdfUri(intent: Intent?): Uri? {
        if (intent == null) return null
        val uri =
            when (intent.action) {
                Intent.ACTION_VIEW -> intent.data
                Intent.ACTION_SEND ->
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                        intent.getParcelableExtra(Intent.EXTRA_STREAM, Uri::class.java)
                    } else {
                        @Suppress("DEPRECATION")
                        intent.getParcelableExtra<Uri>(Intent.EXTRA_STREAM)
                    }
                else -> null
            } ?: return null
        if (uri.scheme != "content") return null
        val type = intent.type ?: contentResolver.getType(uri)
        val isPdf = type == PDF_MIME || displayName(uri)?.endsWith(".pdf", true) == true
        return if (isPdf) uri else null
    }

    private fun displayName(uri: Uri): String? =
        contentResolver
            .query(uri, arrayOf(OpenableColumns.DISPLAY_NAME), null, null, null)
            ?.use { cursor -> if (cursor.moveToFirst()) cursor.getString(0) else null }

    private fun copyToCache(uri: Uri): Map<String, Any> {
        // `name` keeps the user's file name (title); only the cache file name
        // is sanitized.
        val name = displayName(uri)?.takeIf { it.isNotBlank() } ?: DEFAULT_NAME
        val safe = name.replace(Regex("[^A-Za-z0-9 ._-]"), "_").take(MAX_FILE_NAME)
        val fileName = if (safe.endsWith(".pdf", true)) safe else "$safe.pdf"
        val dir = File(cacheDir, INCOMING_DIR).apply { mkdirs() }
        val target = File(dir, "${System.currentTimeMillis()}_$fileName")
        try {
            val input = contentResolver.openInputStream(uri) ?: error("No stream for $uri")
            input.use { source -> target.outputStream().use { source.copyTo(it) } }
        } catch (e: Exception) {
            target.delete()
            throw e
        }
        return mapOf("path" to target.absolutePath, "name" to name, "size" to target.length())
    }

    private fun deliver(item: Pending) {
        val ch = channel
        if (dartReady && ch != null) {
            ch.invokeMethod(item.method, item.payload)
        } else {
            pending.add(item)
        }
    }

    /** A channel call waiting for Dart: `onPdf` or `onPdfError` with its map. */
    private data class Pending(val method: String, val payload: Map<String, Any>)

    private companion object {
        const val CHANNEL = "elyanotes/incoming_pdf"
        const val ON_PDF = "onPdf"
        const val ON_PDF_ERROR = "onPdfError"
        const val DEFAULT_NAME = "document.pdf"
        const val MAX_CAUSE_DEPTH = 10
        const val PDF_MIME = "application/pdf"
        const val TAG = "IncomingPdf"
        const val MAX_FILE_NAME = 100
        const val INCOMING_DIR = "incoming"
        const val STALE_AFTER_MS = 24L * 60 * 60 * 1000
    }
}
