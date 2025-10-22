import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services") // Google Services plugin
}

// Load keystore properties from key.properties (optional for testing)
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

fun requireKeystoreProperty(key: String): String =
    requireNotNull(keystoreProperties[key] as String?) { "Missing '$key' in key.properties file." }

android {
    namespace = "com.sarthak.quiz"
    compileSdk = 36
    ndkVersion = "27.0.12077973"

    compileOptions {
        isCoreLibraryDesugaringEnabled = true // ✅ FIXED: Added "is" prefix
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = "11"
    }

    defaultConfig {
        applicationId = "com.sarthak.quiz"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
    }

    signingConfigs {
        create("release") {
            // For testing phase: use debug signing or configure proper keystore
            if (keystorePropertiesFile.exists()) {
                try {
                    storeFile = file(requireKeystoreProperty("storeFile"))
                    storePassword = requireKeystoreProperty("storePassword")
                    keyAlias = requireKeystoreProperty("keyAlias")
                    keyPassword = requireKeystoreProperty("keyPassword")
                } catch (e: Exception) {
                    // Fall back to debug signing if keystore properties are missing
                    println("Keystore properties missing, using debug signing for release builds")
                }
            }
        }
    }

   buildTypes {
    release {
        isMinifyEnabled = true
        isShrinkResources = true
        proguardFiles(
            getDefaultProguardFile("proguard-android-optimize.txt"),
            "proguard-rules.pro"
        )
        signingConfig = signingConfigs.getByName("debug") // Use debug for now
        
        // Add these for better APK optimization
        isDebuggable = false
        renderscriptOptimLevel = 3
    }
}

}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    implementation("androidx.window:window:1.0.0")
    implementation("androidx.window:window-java:1.0.0")
    // Add any additional dependencies here if needed
}
