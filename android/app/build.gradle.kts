plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.barber_go"
    compileSdk = flutter.compileSdkVersion
    
    compileOptions {
        // AKTIFKAN DESUGARING UNTUK NOTIFIKASI
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.example.barber_go"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
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

dependencies {
    // VERSI TERBARU UNTUK KOMPATIBILITAS LEBIH BAIK
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")
}
