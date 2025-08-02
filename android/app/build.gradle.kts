import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services") // Google Services plugin
}

// Load keystore properties from key.properties
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

fun requireKeystoreProperty(key: String): String =
    requireNotNull(keystoreProperties[key] as String?) { "Missing '$key' in key.properties file." }

android {
    namespace = "com.sarthak.quiz"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.sarthak.quiz"
        minSdk = 23 // Updated for Firebase requirement
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }
signingConfigs {
    create("release") {
        // Temporarily disabled for debug builds
        /*
        if (keystorePropertiesFile.exists()) {
            storeFile = file(requireKeystoreProperty("storeFile"))
            storePassword = requireKeystoreProperty("storePassword")
            keyAlias = requireKeystoreProperty("keyAlias")
            keyPassword = requireKeystoreProperty("keyPassword")
        }
        */
    }
}


    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

flutter {
    source = "../.."
}
