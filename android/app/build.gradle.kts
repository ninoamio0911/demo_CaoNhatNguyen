plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.caonhatnguyen"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17

        // --- QUAN TRỌNG 1: Bật tính năng Desugaring (Cú pháp Kotlin) ---
        isCoreLibraryDesugaringEnabled = true
        // ---------------------------------------------------------------
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.example.caonhatnguyen"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // --- QUAN TRỌNG: Thêm dòng này để tránh lỗi Multidex ---
        multiDexEnabled = true
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

// --- QUAN TRỌNG 2: Thêm thư viện Desugar (Cú pháp Kotlin) ---
dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}
// ------------------------------------------------------------