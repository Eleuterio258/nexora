package com.e258tech.cbescanner.cbescanner

import android.app.Activity
import android.content.Intent
import android.content.IntentSender
import com.google.mlkit.vision.documentscanner.GmsDocumentScannerOptions
import com.google.mlkit.vision.documentscanner.GmsDocumentScanning
import com.google.mlkit.vision.documentscanner.GmsDocumentScanningResult
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "cbescanner/document_scanner"
    private val scanRequestCode = 0x5CA1

    private var pendingResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "scanDocument" -> {
                        val pageLimit = call.argument<Int>("pageLimit") ?: 300
                        startDocumentScan(pageLimit, result)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun startDocumentScan(pageLimit: Int, result: MethodChannel.Result) {
        if (pendingResult != null) {
            result.error("BUSY", "A scan is already in progress", null)
            return
        }
        pendingResult = result

        val options = GmsDocumentScannerOptions.Builder()
            .setGalleryImportAllowed(false)
            .setPageLimit(pageLimit)
            .setResultFormats(GmsDocumentScannerOptions.RESULT_FORMAT_PDF)
            .setScannerMode(GmsDocumentScannerOptions.SCANNER_MODE_FULL)
            .build()

        val scanner = GmsDocumentScanning.getClient(options)
        scanner.getStartScanIntent(this)
            .addOnSuccessListener { intentSender ->
                try {
                    startIntentSenderForResult(intentSender, scanRequestCode, null, 0, 0, 0)
                } catch (e: IntentSender.SendIntentException) {
                    finishPendingResult { it.error("SEND_INTENT_FAILED", e.message, null) }
                }
            }
            .addOnFailureListener { e ->
                finishPendingResult { it.error("SCANNER_UNAVAILABLE", e.message, null) }
            }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (requestCode != scanRequestCode) {
            super.onActivityResult(requestCode, resultCode, data)
            return
        }

        when (resultCode) {
            Activity.RESULT_OK -> {
                val scanningResult = GmsDocumentScanningResult.fromActivityResultIntent(data)
                val pdfUri = scanningResult?.pdf?.uri?.toString()?.removePrefix("file://")
                if (pdfUri != null) {
                    finishPendingResult { it.success(pdfUri) }
                } else {
                    finishPendingResult { it.error("NO_PDF", "O scanner não devolveu um PDF", null) }
                }
            }
            Activity.RESULT_CANCELED -> finishPendingResult { it.success(null) }
            else -> finishPendingResult { it.error("SCAN_FAILED", "Código de resultado $resultCode", null) }
        }
    }

    private fun finishPendingResult(action: (MethodChannel.Result) -> Unit) {
        val result = pendingResult ?: return
        pendingResult = null
        action(result)
    }
}
