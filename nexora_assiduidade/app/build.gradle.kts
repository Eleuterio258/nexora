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

        buildConfigField("String", "ERP_BASE_URL", "\"http://10.0.2.2:8080/\"")
        buildConfigField("String", "ASSIDUIDADE_BASE_URL", "\"http://10.0.2.2:8001/api/v1/\"")
    }

    buildTypes {
        release {
            isMinifyEnabled = false
            buildConfigField("String", "ERP_BASE_URL", "\"https://api.nexora.e258tech.tech/\"")
            buildConfigField("String", "ASSIDUIDADE_BASE_URL", "\"https://asseduidade.e258tech.tech/api/v1/\"")
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
        debug {
            buildConfigField("String", "ERP_BASE_URL", "\"http://192.168.168.171:8080/\"")
            buildConfigField("String", "ASSIDUIDADE_BASE_URL", "\"http://10.0.2.2:8001/api/v1/\"")
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
    testImplementation(libs.junit)
    androidTestImplementation(libs.androidx.junit)
    androidTestImplementation(libs.androidx.espresso.core)
}
