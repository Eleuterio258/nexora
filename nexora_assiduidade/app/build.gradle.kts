import java.util.Properties

plugins {
    alias(libs.plugins.android.application)
    alias(libs.plugins.kotlin.android)
    alias(libs.plugins.ksp)
}

// Chave de device do Nexora ERP (hardware.devices) — usada pelos endpoints
// /api/hardware/* chamados directamente pela app desde 2026-07-13. Nao
// commitar o valor real: define DEVICE_API_KEY em local.properties (nao
// versionado) ou na variavel de ambiente DEVICE_API_KEY (CI de release).
// AVISO: uma vez publicada no APK, esta chave e extraivel por descompilacao —
// risco aceite explicitamente para os metodos alternativos de assiduidade
// (qr/nfc/geolocation/registo de ponto), ver CONTRATO-INTEGRACAO-ERP.md.
val localProperties = Properties().apply {
    val file = rootProject.file("local.properties")
    if (file.exists()) file.inputStream().use { load(it) }
}
fun deviceApiKey(): String =
    (localProperties.getProperty("DEVICE_API_KEY") ?: System.getenv("DEVICE_API_KEY") ?: "").let {
        "\"$it\""
    }

android {
    namespace = "tech.e258tech.nexora_assiduidade"
    compileSdk = 36

    defaultConfig {
        applicationId = "tech.e258tech.nexora_assiduidade"
        minSdk = 24
        targetSdk = 36
        versionCode = 1
        versionName = "1.0"
        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"

        buildConfigField("String", "ERP_BASE_URL", "\"http://10.0.2.2:8080/\"")
        buildConfigField("String", "ASSIDUIDADE_BASE_URL", "\"http://10.0.2.2:8001/api/v1/\"")
        buildConfigField("String", "DEVICE_API_KEY", deviceApiKey())
    }

    buildTypes {
        release {
            isMinifyEnabled = false
            buildConfigField("String", "ERP_BASE_URL", "\"https://api.nexora.e258tech.tech/\"")
            buildConfigField("String", "ASSIDUIDADE_BASE_URL", "\"https://asseduidade.e258tech.tech/api/v1/\"")
            buildConfigField("String", "DEVICE_API_KEY", deviceApiKey())
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
        debug {
            buildConfigField("String", "ERP_BASE_URL", "\"http://10.0.2.2:8080/\"")
            buildConfigField("String", "ASSIDUIDADE_BASE_URL", "\"http://10.0.2.2:8001/api/v1/\"")
            buildConfigField("String", "DEVICE_API_KEY", deviceApiKey())
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }
    kotlinOptions { jvmTarget = "11" }
    buildFeatures {
        viewBinding = true
        buildConfig = true
    }
}

dependencies {
    implementation(libs.androidx.core.ktx)
    implementation(libs.androidx.appcompat)
    implementation(libs.material)
    implementation(libs.lifecycle.viewmodel)
    implementation(libs.lifecycle.livedata)
    implementation(libs.navigation.fragment)
    implementation(libs.navigation.ui)
    implementation(libs.retrofit)
    implementation(libs.retrofit.gson)
    implementation(libs.okhttp.logging)
    implementation(libs.gson)
    implementation(libs.coroutines.android)
    implementation(libs.coroutines.play.services)
    implementation(libs.security.crypto)
    implementation(libs.swiperefreshlayout)
    implementation(libs.androidx.constraintlayout)
    implementation(libs.zxing)
    implementation(libs.zxing.embedded)
    implementation(libs.biometric)
    implementation(libs.room.runtime)
    implementation(libs.room.ktx)
    ksp(libs.room.compiler)
    implementation(libs.work.manager)
    implementation(libs.play.services.location)
    implementation(libs.camera.core)
    implementation(libs.camera.camera2)
    implementation(libs.camera.lifecycle)
    implementation(libs.camera.view)
    implementation(libs.mediapipe.tasks.vision)
    testImplementation(libs.junit)
    androidTestImplementation(libs.androidx.junit)
    androidTestImplementation(libs.androidx.espresso.core)
}
