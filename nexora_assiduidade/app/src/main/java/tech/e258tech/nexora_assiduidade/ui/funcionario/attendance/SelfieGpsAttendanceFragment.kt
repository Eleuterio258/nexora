package tech.e258tech.nexora_assiduidade.ui.funcionario.attendance

import android.Manifest
import android.app.Activity
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.location.Location
import android.os.Bundle
import android.provider.MediaStore
import android.util.Base64
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.Button
import android.widget.ImageView
import android.widget.ProgressBar
import android.widget.RadioGroup
import android.widget.TextView
import android.widget.Toast
import androidx.activity.result.contract.ActivityResultContracts
import androidx.core.content.ContextCompat
import androidx.fragment.app.Fragment
import com.google.android.gms.location.FusedLocationProviderClient
import com.google.android.gms.location.LocationServices
import java.io.ByteArrayOutputStream
import java.util.UUID
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch
import kotlinx.coroutines.tasks.await
import kotlinx.coroutines.withContext
import tech.e258tech.nexora_assiduidade.R
import tech.e258tech.nexora_assiduidade.data.model.ClockRegisterRequest
import tech.e258tech.nexora_assiduidade.data.repository.AttendanceRepository
import tech.e258tech.nexora_assiduidade.utils.Constants
import tech.e258tech.nexora_assiduidade.utils.DateTimeUtils
import tech.e258tech.nexora_assiduidade.utils.SessionManager

/**
 * Tela de registo de presenca por selfie + GPS.
 *
 * Captura uma selfie e obtem a localizacao atual do dispositivo. O geofencing
 * real (`GET /api/hardware/assiduidade/geofence/validar` no Nexora ERP)
 * exige um `unidade_id` que este ecra nao recolhe (sem selector de unidade),
 * tal como acontecia no proxy do FaceClock — por isso continua permissivo
 * aqui, so regista as coordenadas para auditoria. O registo e enviado com os
 * metadados de localizacao e a selfie como prova de presenca.
 */
class SelfieGpsAttendanceFragment : Fragment() {

    private val uiScope = CoroutineScope(SupervisorJob() + Dispatchers.Main)

    private lateinit var sessionManager: SessionManager
    private lateinit var attendanceRepository: AttendanceRepository
    private lateinit var fusedLocationClient: FusedLocationProviderClient

    private lateinit var radioGroupType: RadioGroup
    private lateinit var btnCaptureSelfie: Button
    private lateinit var progressBar: ProgressBar
    private lateinit var ivSelfie: ImageView
    private lateinit var tvLocation: TextView

    private var currentLocation: Location? = null
    private var lastSelfieBase64: String? = null

    private val cameraLauncher = registerForActivityResult(
        ActivityResultContracts.StartActivityForResult()
    ) { result ->
        if (result.resultCode == Activity.RESULT_OK) {
            val bitmap = result.data?.extras?.get("data") as? Bitmap
            if (bitmap != null) {
                ivSelfie.setImageBitmap(bitmap)
                ivSelfie.visibility = View.VISIBLE
                lastSelfieBase64 = bitmapToBase64(bitmap)
                validateLocationAndRegister()
            } else {
                Toast.makeText(context, "Falha ao capturar selfie.", Toast.LENGTH_SHORT).show()
                setLoading(false)
            }
        } else {
            setLoading(false)
        }
    }

    private val locationPermissionLauncher = registerForActivityResult(
        ActivityResultContracts.RequestMultiplePermissions()
    ) { permissions: Map<String, Boolean> ->
        val granted = permissions.entries.any { it.value }
        if (granted) {
            fetchLocation()
        } else {
            tvLocation.text = "Permissao de localizacao negada."
        }
    }

    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View {
        return inflater.inflate(R.layout.funcionario_selfie_gps_attendance, container, false)
    }

    override fun onDestroyView() {
        uiScope.cancel()
        super.onDestroyView()
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)

        sessionManager = SessionManager(requireContext())
        attendanceRepository = AttendanceRepository(requireContext())
        fusedLocationClient = LocationServices.getFusedLocationProviderClient(requireContext())

        radioGroupType = view.findViewById(R.id.radioGroupType)
        btnCaptureSelfie = view.findViewById(R.id.btnCaptureSelfie)
        progressBar = view.findViewById(R.id.progressBar)
        ivSelfie = view.findViewById(R.id.ivSelfie)
        tvLocation = view.findViewById(R.id.tvLocation)

        fetchLocation()

        btnCaptureSelfie.setOnClickListener {
            val selectedId = radioGroupType.checkedRadioButtonId
            if (selectedId == -1) {
                Toast.makeText(context, "Selecione Entrada ou Saida", Toast.LENGTH_SHORT).show()
                return@setOnClickListener
            }
            openCamera()
        }
    }

    private fun fetchLocation() {
        val hasFine = ContextCompat.checkSelfPermission(requireContext(), Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED
        val hasCoarse = ContextCompat.checkSelfPermission(requireContext(), Manifest.permission.ACCESS_COARSE_LOCATION) == PackageManager.PERMISSION_GRANTED
        if (!hasFine && !hasCoarse) {
            locationPermissionLauncher.launch(
                arrayOf(
                    Manifest.permission.ACCESS_FINE_LOCATION,
                    Manifest.permission.ACCESS_COARSE_LOCATION
                )
            )
            return
        }

        uiScope.launch {
            try {
                val location = withContext(Dispatchers.IO) {
                    fusedLocationClient.lastLocation.await()
                }
                currentLocation = location
                if (location != null) {
                    tvLocation.text = "Localizacao: %.6f, %.6f".format(location.latitude, location.longitude)
                } else {
                    tvLocation.text = "A obter localizacao..."
                }
            } catch (e: Exception) {
                tvLocation.text = "Erro ao obter localizacao."
            }
        }
    }

    private fun openCamera() {
        val intent = Intent(MediaStore.ACTION_IMAGE_CAPTURE)
        if (intent.resolveActivity(requireActivity().packageManager) != null) {
            setLoading(true)
            cameraLauncher.launch(intent)
        } else {
            Toast.makeText(context, "Camara nao disponivel.", Toast.LENGTH_SHORT).show()
        }
    }

    private fun validateLocationAndRegister() {
        val userId = sessionManager.getUserId()
        val token = sessionManager.getToken()
        val location = currentLocation
        val selfie = lastSelfieBase64

        if (userId.isNullOrBlank() || token.isNullOrBlank()) {
            setLoading(false)
            Toast.makeText(context, "Sessao invalida. Faca login novamente.", Toast.LENGTH_LONG).show()
            return
        }

        if (location == null) {
            setLoading(false)
            Toast.makeText(context, "Localizacao indisponivel. Tente novamente.", Toast.LENGTH_LONG).show()
            return
        }

        if (selfie.isNullOrBlank()) {
            setLoading(false)
            Toast.makeText(context, "Selfie nao capturada.", Toast.LENGTH_LONG).show()
            return
        }

        val selectedId = radioGroupType.checkedRadioButtonId
        val eventType = if (selectedId == R.id.radioEntrada) {
            Constants.EVENT_ENTRY
        } else {
            Constants.EVENT_EXIT
        }

        uiScope.launch {
            // Sem unidade seleccionada nao ha geofencing real a validar (ver
            // nota na classe) — mantem-se permissivo, tal como o proxy do
            // FaceClock fazia quando unit_id vinha vazio.
            val request = ClockRegisterRequest(
                idempotency_key = UUID.randomUUID().toString(),
                user_id = userId,
                device_id = sessionManager.getOrCreateDeviceId(),
                event_type = eventType,
                recorded_at = DateTimeUtils.nowForApi(),
                source = Constants.SOURCE_GEOLOCATION,
                geo_lat = location.latitude,
                geo_lng = location.longitude,
                image_base64 = selfie
            )

            val registerResult = withContext(Dispatchers.IO) {
                attendanceRepository.registerClock(request)
            }

            setLoading(false)
            val action = if (eventType == Constants.EVENT_ENTRY) "entrada" else "saida"

            when (registerResult) {
                is AttendanceRepository.RegisterResult.Success -> {
                    Toast.makeText(
                        context,
                        "Registo de $action realizado com sucesso.",
                        Toast.LENGTH_SHORT
                    ).show()
                    parentFragmentManager.popBackStack()
                }
                is AttendanceRepository.RegisterResult.SavedOffline -> {
                    Toast.makeText(
                        context,
                        "Sem internet. Registo de $action guardado e sera sincronizado automaticamente.",
                        Toast.LENGTH_LONG
                    ).show()
                    parentFragmentManager.popBackStack()
                }
                is AttendanceRepository.RegisterResult.Error -> {
                    Toast.makeText(context, registerResult.message, Toast.LENGTH_LONG).show()
                }
            }
        }
    }

    private fun bitmapToBase64(bitmap: Bitmap): String {
        val outputStream = ByteArrayOutputStream()
        bitmap.compress(Bitmap.CompressFormat.JPEG, 85, outputStream)
        val bytes = outputStream.toByteArray()
        return Base64.encodeToString(bytes, Base64.NO_WRAP)
    }

    private fun setLoading(isLoading: Boolean) {
        btnCaptureSelfie.isEnabled = !isLoading
        progressBar.visibility = if (isLoading) View.VISIBLE else View.GONE
    }
}
