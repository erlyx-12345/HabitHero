plugins {
    id("com.android.application") version "8.11.1" apply true
    id("org.jetbrains.kotlin.android") version "2.2.20" apply true
    id("dev.flutter.flutter-gradle-plugin") apply true
}

android {
    namespace = "com.example.habit_hero"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.example.habit_hero"
        minSdk = flutter.minSdkVersion 
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        
        multiDexEnabled = true
    }

    buildTypes {
        getByName("release") {
            // If you haven't set up a release keystore yet, 
            // comment out the signingConfig line below.
            // signingConfig = signingConfigs.getByName("release")
            
            isMinifyEnabled = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
} // Fixed: Added missing closing bracket for the 'android' block

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.3")
}