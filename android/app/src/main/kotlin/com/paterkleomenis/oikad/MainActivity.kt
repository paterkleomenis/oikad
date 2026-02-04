package com.paterkleomenis.oikad

import android.content.ContentValues
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.OutputStream

class MainActivity : FlutterActivity() {
    private val INSTALLER_CHANNEL = "com.example.oikad/installer"
    private val PERMISSION_CHANNEL = "flutter.dev/install_permission"
    private val RECEIPT_SAVER_CHANNEL = "com.paterkleomenis.oikad/receipt_saver"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Installer channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, INSTALLER_CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method == "installApk") {
                    val filePath = call.argument<String>("filePath")
                    if (filePath != null) {
                        val success = installApk(filePath)
                        result.success(success)
                    } else {
                        result.error("INVALID_ARGUMENT", "File path is null", null)
                    }
                } else {
                    result.notImplemented()
                }
            }

        // Install permission channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, PERMISSION_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "canRequestPackageInstalls" -> {
                        val canInstall = canRequestPackageInstalls()
                        result.success(canInstall)
                    }

                    else -> {
                        result.notImplemented()
                    }
                }
            }

        // Receipt saver channel (save directly to Downloads)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, RECEIPT_SAVER_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "saveToDownloads" -> {
                        val fileName = call.argument<String>("fileName")
                        val bytes = call.argument<ByteArray>("bytes")
                        if (fileName == null || bytes == null) {
                            result.error("INVALID_ARGUMENT", "Missing fileName or bytes", null)
                            return@setMethodCallHandler
                        }

                        try {
                            val savedPath = saveToDownloads(fileName, bytes)
                            if (savedPath == null) {
                                result.error("IO_ERROR", "Failed to save file", null)
                            } else {
                                result.success(savedPath)
                            }
                        } catch (e: Exception) {
                            e.printStackTrace()
                            result.error("IO_ERROR", e.message, null)
                        }
                    }

                    else -> {
                        result.notImplemented()
                    }
                }
            }

    }

    private fun canRequestPackageInstalls(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            packageManager.canRequestPackageInstalls()
        } else {
            // On older versions, this permission is granted by default
            true
        }
    }

    private fun installApk(filePath: String): Boolean {
        return try {
            val file = File(filePath)
            if (!file.exists()) {
                false
            } else {
                val intent = Intent(Intent.ACTION_VIEW)
                intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK

                val uri =
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                        FileProvider.getUriForFile(this, "$packageName.fileprovider", file)
                    } else {
                        Uri.fromFile(file)
                    }

                intent.setDataAndType(uri, "application/vnd.android.package-archive")
                intent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)

                startActivity(intent)
                true
            }
        } catch (e: Exception) {
            e.printStackTrace()
            false
        }
    }

    private fun saveToDownloads(fileName: String, bytes: ByteArray): String? {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val resolver = applicationContext.contentResolver
            val collection = MediaStore.Downloads.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
            val values = ContentValues().apply {
                put(MediaStore.Downloads.DISPLAY_NAME, fileName)
                put(MediaStore.Downloads.MIME_TYPE, "application/pdf")
                put(MediaStore.Downloads.IS_PENDING, 1)
            }

            val itemUri = resolver.insert(collection, values) ?: return null
            val outputStream: OutputStream? = resolver.openOutputStream(itemUri, "w")
            if (outputStream == null) return null

            outputStream.use { stream ->
                stream.write(bytes)
                stream.flush()
            }

            values.clear()
            values.put(MediaStore.Downloads.IS_PENDING, 0)
            resolver.update(itemUri, values, null, null)
            itemUri.toString()
        } else {
            val downloadsDir =
                Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS)
            val file = File(downloadsDir, fileName)
            file.writeBytes(bytes)
            file.path
        }
    }
}
