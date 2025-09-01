package com.oikad.app

import android.content.Intent
import android.net.Uri
import android.os.Build
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private val INSTALLER_CHANNEL = "com.example.oikad/installer"
    private val PERMISSION_CHANNEL = "flutter.dev/install_permission"

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
}
