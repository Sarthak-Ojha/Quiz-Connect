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
    compileSdk = 35
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
        minSdk = 23
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
        debug {
            signingConfig = signingConfigs.getByName("debug")
            isDebuggable = true
            isMinifyEnabled = false
            isShrinkResources = false
        }
        
        release {
            // Use debug signing for testing phase
            signingConfig = signingConfigs.getByName("debug")
            isMinifyEnabled = false
            isShrinkResources = false
            
            // Uncomment below line when you have proper release keystore
            // signingConfig = signingConfigs.getByName("release")
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
