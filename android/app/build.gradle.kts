import java.util.Properties

plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}


android {
    namespace = "fr.sarrazi.asso"
    compileSdk = 36
    ndkVersion= "29.0.13113456 rc1"

    // Chargement du fichier key.properties (si présent)
    val keystorePropertiesFile = rootProject.file("key.properties")
    val keystoreProperties = Properties().apply {
        if (keystorePropertiesFile.exists()) {
            load(keystorePropertiesFile.inputStream())
        }
    }

    // ---- Gestion robuste des versions ----
    // Essaie d'abord les propriétés passées par Flutter (nouvelles et anciennes),
    // puis les variables d'environnement (Android Studio), sinon valeurs de repli sûres.
    val fallbackVersionCode = "1012"   // <-- tu peux mettre la valeur que tu veux publier maintenant
    val fallbackVersionName = "1.1.1"

    val flutterVersionCodeStr =
        (project.findProperty("flutter.versionCode")?.toString()
            ?: project.findProperty("flutterVersionCode")?.toString()
            ?: System.getenv("FLUTTER_BUILD_NUMBER")
            ?: fallbackVersionCode)

    val flutterVersionNameStr =
        (project.findProperty("flutter.versionName")?.toString()
            ?: project.findProperty("flutterVersionName")?.toString()
            ?: System.getenv("FLUTTER_BUILD_NAME")
            ?: fallbackVersionName)

    defaultConfig {
        applicationId = "fr.sarrazi.asso"
        minSdk = flutter.minSdkVersion
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties.getProperty("keyAlias")
            keyPassword = keystoreProperties.getProperty("keyPassword")
            storeFile = keystoreProperties.getProperty("storeFile")?.let { file(it) }
            storePassword = keystoreProperties.getProperty("storePassword")
        }
    }

    buildTypes {
        getByName("release") {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = "17"
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation("androidx.window:window:1.0.0")
    implementation("androidx.window:window-java:1.0.0")
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")

    // Firebase (version Kotlin DSL)
    implementation(platform("com.google.firebase:firebase-bom:32.7.0"))
    implementation("com.google.firebase:firebase-messaging:23.4.0")
}
