pluginManagement {
    // Baca path Flutter SDK dari local.properties
    val flutterSdkPath = run {
        val properties = java.util.Properties()
        val localProperties = file("local.properties")
        if (localProperties.exists()) {
            localProperties.inputStream().use { properties.load(it) }
        }
        val flutterSdk = properties.getProperty("flutter.sdk")
        require(flutterSdk != null) {
            "flutter.sdk not set in local.properties"
        }
        flutterSdk
    }

    // Ini yang bikin plugin dev.flutter.flutter-plugin-loader ketemu
    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "8.7.3" apply false
    id("org.jetbrains.kotlin.android") version "2.0.21" apply false
    // Kalau pakai Firebase, boleh sekalian:
    id("com.google.gms.google-services") version "4.4.2" apply false
}

include(":app")
