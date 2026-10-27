import com.google.firebase.crashlytics.buildtools.gradle.CrashlyticsExtension
import com.google.gms.googleservices.GoogleServicesPlugin.MissingGoogleServicesStrategy
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("com.google.gms.google-services")
    id("com.google.firebase.crashlytics")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Release signing (#192): env vars (CI, see scripts/release-secrets.sh) win over
// android/key.properties (local, git-ignored). Without either, release builds
// fall back to debug signing unless ELYANOTES_REQUIRE_RELEASE_SIGNING=true.
val keyProperties =
    Properties().apply {
        val file = rootProject.file("key.properties")
        if (file.exists()) file.inputStream().use { load(it) }
    }

fun signingValue(
    env: String,
    property: String,
): String? = System.getenv(env)?.takeIf { it.isNotBlank() } ?: keyProperties.getProperty(property)

val releaseStoreFile = signingValue("ANDROID_KEYSTORE_PATH", "storeFile")
val releaseStorePassword = signingValue("ANDROID_KEYSTORE_PASSWORD", "storePassword")
val releaseKeyAlias = signingValue("ANDROID_KEY_ALIAS", "keyAlias")
val releaseKeyPassword = signingValue("ANDROID_KEY_PASSWORD", "keyPassword")
val hasReleaseSigning =
    listOf(releaseStoreFile, releaseStorePassword, releaseKeyAlias, releaseKeyPassword)
        .all { !it.isNullOrBlank() }
val requireReleaseSigning = System.getenv("ELYANOTES_REQUIRE_RELEASE_SIGNING") == "true"

// Firebase native config (#215): written by scripts/release-secrets.sh from the
// FIREBASE_* secrets, git-ignored, absent in local and PR builds. Without it the
// google-services plugin only warns and no Crashlytics upload is attempted.
val hasGoogleServices = file("google-services.json").exists()

googleServices {
    missingGoogleServicesStrategy = MissingGoogleServicesStrategy.WARN
}

android {
    namespace = "com.aktasilyas.elyanotes"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.aktasilyas.elyanotes"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseSigning) {
            create("release") {
                storeFile = file(releaseStoreFile!!)
                storePassword = releaseStorePassword
                keyAlias = releaseKeyAlias
                keyPassword = releaseKeyPassword
            }
        }
    }

    buildTypes {
        release {
            signingConfig =
                when {
                    hasReleaseSigning -> signingConfigs.getByName("release")
                    requireReleaseSigning -> throw GradleException(
                        "Release signing required (ELYANOTES_REQUIRE_RELEASE_SIGNING=true) but no " +
                            "keystore configured: set ANDROID_KEYSTORE_PATH, ANDROID_KEYSTORE_PASSWORD, " +
                            "ANDROID_KEY_ALIAS, ANDROID_KEY_PASSWORD or android/key.properties.",
                    )
                    // Local `flutter run --release` and the unsigned CI check build.
                    else -> signingConfigs.getByName("debug")
                }
            // R8 shrinking + obfuscation; rules in proguard-rules.pro (#192).
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
            // R8 mapping.txt is uploaded to Crashlytics automatically when Firebase
            // config is present (#215). Dart code is not obfuscated, so Dart stacks
            // are readable without symbols; there is no native code of our own.
            configure<CrashlyticsExtension> {
                mappingFileUploadEnabled = hasGoogleServices
                nativeSymbolUploadEnabled = false
            }
        }
    }
}

flutter {
    source = "../.."
}
