package com.aktasilyas.elyanotes

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.provider.OpenableColumns
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
 * {path, name, size}. Dart imports it into app storage and deletes the copy,
 * so no persistable URI permission is needed. Items received before Dart is
 * listening (cold start) are buffered until Dart calls `ready`.
 */
class MainActivity : FlutterFragmentActivity() {
    private val executor = Executors.newSingleThreadExecutor()
    private val mainHandler = Handler(Looper.getMainLooper())
    private val pending = mutableListOf<Map<String, Any>>()
    private var channel: MethodChannel? = null
    private var dartReady = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        channel =
            MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).apply {
                setMethodCallHandler { call, result ->
                    if (call.method == "ready") {
                        dartReady = true
                        result.success(pending.toList())
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
                    copyToCache(uri)
                } catch (e: Exception) {
                    Log.w(TAG, "Could not read incoming PDF", e)
                    null
                }
            if (item != null) mainHandler.post { deliver(item) }
        }
    }

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
        val name = displayName(uri)?.takeIf { it.isNotBlank() } ?: "document.pdf"
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

    private fun deliver(item: Map<String, Any>) {
        val ch = channel
        if (dartReady && ch != null) ch.invokeMethod("onPdf", item) else pending.add(item)
    }

    private companion object {
        const val CHANNEL = "elyanotes/incoming_pdf"
        const val PDF_MIME = "application/pdf"
        const val TAG = "IncomingPdf"
        const val MAX_FILE_NAME = 100
        const val INCOMING_DIR = "incoming"
        const val STALE_AFTER_MS = 24L * 60 * 60 * 1000
    }
}
