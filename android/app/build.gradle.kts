pluginManagement {
    val flutterSdkPath = run {
        val properties = java.util.Properties()
        val propertiesFile = java.io.File(settingsDir, "local.properties")
        if (propertiesFile.exists()) {
            propertiesFile.inputStream().use { properties.load(it) }
        }
        properties.getProperty("flutter.sdk")
    }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        maven { 
            url = uri("http://repo.maven.apache.org/maven2/")
            isAllowInsecureProtocol = true
        }
        maven { 
            url = uri("http://plugins.gradle.org/m2/")
            isAllowInsecureProtocol = true
        }
        google {
            isAllowInsecureProtocol = true
        }
        mavenCentral {
            isAllowInsecureProtocol = true
        }
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "8.7.0" apply false
    id("org.jetbrains.kotlin.android") version "1.8.22" apply false
}

include(":app")