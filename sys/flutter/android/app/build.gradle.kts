plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "jp.satokiyo.darthack"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "jp.satokiyo.darthack"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        val verFile = file("../../assets/ver")
        val assetVersion = if (verFile.exists()) {
            verFile.readText().trim().toIntOrNull() ?: 0
        } else {
            0
        }
        versionCode = (flutter.versionCode ?: 1) + assetVersion
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }

    externalNativeBuild {
        cmake {
            path = file("src/main/cpp/CMakeLists.txt")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

tasks.register<Exec>("syncDatAssets") {
    workingDir = file("$rootDir/../../..")
    commandLine("powershell", "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", file("$rootDir/../scripts/sync_dat_assets.ps1").absolutePath)
}


tasks.named("preBuild") {
    dependsOn("syncDatAssets")
}

