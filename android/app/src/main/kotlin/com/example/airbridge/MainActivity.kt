package com.example.airbridge

import android.content.Intent
import android.net.Uri
import android.provider.OpenableColumns
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream

class MainActivity : FlutterActivity() {
    private val channelName = "airbridge/share"
    private var methodChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "getSharedFiles" -> result.success(copyIncomingFiles(intent))
                else -> result.notImplemented()
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        val files = copyIncomingFiles(intent)
        if (files.isNotEmpty()) methodChannel?.invokeMethod("sharedFiles", files)
    }

    private fun copyIncomingFiles(sourceIntent: Intent?): List<Map<String, Any>> {
        if (sourceIntent == null) return emptyList()
        val uris = mutableListOf<Uri>()
        when (sourceIntent.action) {
            Intent.ACTION_SEND -> sourceIntent.getParcelableExtra<Uri>(Intent.EXTRA_STREAM)?.let { uris.add(it) }
            Intent.ACTION_SEND_MULTIPLE -> sourceIntent.getParcelableArrayListExtra<Uri>(Intent.EXTRA_STREAM)?.let { uris.addAll(it) }
        }
        val folder = File(cacheDir, "share_inbox").apply { mkdirs() }
        return uris.distinct().mapNotNull { uri ->
            runCatching {
                val name = queryDisplayName(uri) ?: "shared_file"
                val safeName = name.replace(Regex("[^A-Za-z0-9._ -]"), "_").take(120).ifBlank { "shared_file" }
                val target = File.createTempFile("share_", "_" + safeName, folder)
                contentResolver.openInputStream(uri)?.use { input ->
                    FileOutputStream(target).use { output -> input.copyTo(output) }
                } ?: throw IllegalStateException("Unable to read shared file")
                mapOf("name" to name, "path" to target.absolutePath, "size" to target.length())
            }.getOrNull()
        }
    }

    private fun queryDisplayName(uri: Uri): String? {
        if (uri.scheme == "content") {
            contentResolver.query(uri, arrayOf(OpenableColumns.DISPLAY_NAME), null, null, null)?.use { cursor ->
                if (cursor.moveToFirst()) {
                    val index = cursor.getColumnIndex(OpenableColumns.DISPLAY_NAME)
                    if (index >= 0) return cursor.getString(index)
                }
            }
        }
        return uri.lastPathSegment
    }
}
