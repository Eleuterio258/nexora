package tech.e258tech.paycore

import android.app.Activity
import android.content.Intent
import android.os.Bundle
import android.view.KeyEvent
import android.view.View
import androidx.activity.result.contract.ActivityResultContracts
import androidx.appcompat.app.AppCompatActivity
import com.journeyapps.barcodescanner.CaptureManager
import com.journeyapps.barcodescanner.DecoratedBarcodeView

class ScannerActivity : AppCompatActivity() {

    companion object {
        const val EXTRA_BARCODE = "barcode_result"
    }

    private lateinit var capture: CaptureManager
    private lateinit var barcodeView: DecoratedBarcodeView

    private val manualLauncher = registerForActivityResult(
        ActivityResultContracts.StartActivityForResult()
    ) { result ->
        if (result.resultCode == Activity.RESULT_OK) {
            val codigo = result.data?.getStringExtra(EntradaManualActivity.EXTRA_BARCODE).orEmpty()
            if (codigo.isNotEmpty()) {
                setResult(RESULT_OK, Intent().putExtra(EXTRA_BARCODE, codigo))
                finish()
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_scanner)

        barcodeView = findViewById(R.id.barcode_scanner)
        capture = CaptureManager(this, barcodeView)
        capture.initializeFromIntent(intent, savedInstanceState)
        capture.setShowMissingCameraPermissionDialog(true)
        capture.decode()

        barcodeView.decodeContinuous { result ->
            val codigo = result.text ?: return@decodeContinuous
            setResult(RESULT_OK, Intent().putExtra(EXTRA_BARCODE, codigo))
            finish()
        }

        findViewById<View>(R.id.btn_manual).setOnClickListener {
            manualLauncher.launch(Intent(this, EntradaManualActivity::class.java))
        }
    }

    override fun onResume() { super.onResume(); capture.onResume() }
    override fun onPause()  { super.onPause();  capture.onPause()  }
    override fun onDestroy(){ super.onDestroy(); capture.onDestroy() }
    override fun onSaveInstanceState(outState: Bundle) {
        super.onSaveInstanceState(outState)
        capture.onSaveInstanceState(outState)
    }
    override fun onKeyDown(keyCode: Int, event: KeyEvent?) =
        barcodeView.onKeyDown(keyCode, event) || super.onKeyDown(keyCode, event)
}
