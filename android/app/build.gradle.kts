import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services") // Google Services plugin
}

tasks.withType<JavaCompile>().configureEach {
    options.compilerArgs.addAll(
        listOf(
            "-Xlint:deprecation",
            "-Xlint:unchecked",
            "-Xlint:-options"
        )
    )
}

// Load keystore properties from key.properties (optional for testing)
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

fun requireKeystoreProperty(key: String): String =
    requireNotNull(keystoreProperties[key] as String?) { "Missing '$key' in key.properties file." }

// Helper function to read string properties
fun getStringProperty(propertyName: String, defaultValue: String): String {
    return project.findProperty(propertyName)?.toString() ?: defaultValue
}

android {
    namespace = "com.sarthak.quiz"
    compileSdk = 36
    ndkVersion = "27.0.12077973"
    
    // Configure Java compilation
    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_21
        targetCompatibility = JavaVersion.VERSION_21
    }

    // Configure Kotlin compilation
    kotlinOptions {
        jvmTarget = "21"
        freeCompilerArgs = freeCompilerArgs + listOf(
            "-Xjvm-default=all",
            "-Xlambdas=indy",
            "-Xskip-prereference-check",
            "-Xsuppress-version-warnings"
        )
    }

    defaultConfig {
        applicationId = "com.sarthak.quiz"
        minSdk = 24  // Required by flutter_secure_storage
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
    // Add any additional dependencies here if needed
}
