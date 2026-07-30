plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.nexora"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.nexora"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        // 24: mínimo exigido pelo com.google.mediapipe:tasks-vision (ver FaceDetector nativo).
        minSdk = maxOf(flutter.minSdkVersion, 24)
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

// Alinha a 16KB os .so de terceiros (ML Kit via mobile_scanner, MediaPipe
// tasks-vision, CameraX) que ainda não o trazem de origem — issues abertas a
// montante sem previsão (google-ai-edge/mediapipe#6028,
// juliansteenbakker/mobile_scanner#1560), exigido pelo Google Play desde
// 01/11/2025 para apps a visar API 35+. Corre depois de merge*NativeLibs
// (a task que junta os .so de todas as dependências) e antes do
// empacotamento, para o APK/AAB já sair com os ficheiros corrigidos. Ver
// patch_elf_16kb.py para o porquê de nem tudo dar para corrigir só com isto.
tasks.whenTaskAdded {
    if (name.startsWith("merge") && name.endsWith("NativeLibs")) {
        doLast {
            val libDirs = outputs.files.files.filter { it.isDirectory }
            if (libDirs.isEmpty()) return@doLast
            exec {
                commandLine(
                    listOf("python3", "$rootDir/patch_elf_16kb.py") + libDirs.map { it.absolutePath }
                )
            }
        }
    }
}

dependencies {
    // Mesma versão usada no nexora_assiduidade (gradle/libs.versions.toml) para
    // deteção facial em tempo real com o modelo blaze_face_short_range.tflite.
    implementation("com.google.mediapipe:tasks-vision:0.10.35")
}

flutter {
    source = "../.."
}
