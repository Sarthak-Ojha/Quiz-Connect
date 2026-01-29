buildscript {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
    dependencies {
        classpath("com.android.tools.build:gradle:8.1.0")
        classpath("com.google.gms:google-services:4.4.2")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

subprojects {
    project.evaluationDependsOn(":app")
}

// Configure Kotlin compilation for all subprojects
subprojects {
    plugins.withType<org.jetbrains.kotlin.gradle.plugin.KotlinBasePlugin>().configureEach {
        tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
            kotlinOptions {
                jvmTarget = "21"
                freeCompilerArgs = freeCompilerArgs + listOf(
                    "-Xjvm-default=all",
                    "-Xlambdas=indy",
                    "-Xskip-prereference-check",
                    "-Xsuppress-version-warnings"
                )
            }
        }
    }
    
    // Configure Java compilation for all subprojects
    tasks.withType<JavaCompile>().configureEach {
        sourceCompatibility = "21"
        targetCompatibility = "21"
        options.compilerArgs.addAll(listOf(
            "-Xlint:deprecation",
            "-Xlint:unchecked"
        ))
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
