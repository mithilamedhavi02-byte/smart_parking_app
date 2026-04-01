plugins {
    id("com.android.application")
    id("kotlin-android")
    // Firebase ප්ලගිනය (මේක ඔයා කලින් දාලා තිබුණා නම් විතරක් තියන්න)
    id("com.google.gms.google-services")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.parking1"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    // අලුත්ම Flutter ප්‍රමිතියට අනුව jvmTarget එක මෙහෙම ලියන්න
    kotlinOptions {
        jvmTarget = "17"
    }

    defaultConfig {
        // Asgardeo ලොගින් එකට අවශ්‍ය Redirect Scheme එක
        manifestPlaceholders["appAuthRedirectScheme"] = "wso2.asgardeo.io.sample"

        applicationId = "com.example.parking1"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}