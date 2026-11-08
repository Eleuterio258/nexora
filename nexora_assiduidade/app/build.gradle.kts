plugins {
    alias(libs.plugins.android.application)
    alias(libs.plugins.kotlin.android)
    alias(libs.plugins.ksp)
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

        buildConfigField("String", "ERP_BASE_URL", "\"https://api.nexora.e258tech.tech/\"")
    }

    buildTypes {
        release {
            isMinifyEnabled = false
            buildConfigField("String", "ERP_BASE_URL", "\"https://api.nexora.e258tech.tech/\"")
                proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
        debug {
            // 10.0.2.2 so resolve dentro do emulador Android (alias para o
            // localhost da maquina host) — num telemovel fisico aponta para
            // lado nenhum e todas as chamadas de rede falham (incl. login).
            // Debug usa os dominios reais para poder testar em dispositivo
            // fisico; para apontar a um backend local a correr na tua
            // maquina, substitui pelo IP da tua rede local (ex.: 192.168.x.x).
            buildConfigField("String", "ERP_BASE_URL", "\"https://api.nexora.e258tech.tech/\"")
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
