plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "ru.apps78.cotune"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion //"29.0.13599879"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "ru.apps78.cotune"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        ndk {
            abiFilters += listOf("arm64-v8a", "armeabi-v7a", "x86_64")
        }
    }

    packaging {
        jniLibs {
            // Поддержка 16KB page size для Android 15+
            useLegacyPackaging = false
            // Исключаем библиотеки, которые не поддерживают 16KB (временно, до пересборки .aar)
            pickFirsts += listOf("**/libgojni.so", "**/libcotune.so")
        }
        // Подавляем предупреждения о 16KB page size для библиотек, которые будут пересобраны
        resources {
            excludes += listOf("META-INF/DEPENDENCIES", "META-INF/LICENSE")
        }
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

repositories {
    flatDir {
        dirs("libs")
    }
}

dependencies {
    implementation(mapOf("name" to "cotune", "ext" to "aar"))
    implementation("com.journeyapps:zxing-android-embedded:4.3.0")
}

flutter {
    source = "../.."
}

