// Root-level build.gradle.kts

buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath("com.google.gms:google-services:4.3.15")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Shared build directory
val newBuildDir = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.set(newBuildDir)

subprojects {
    val newSubprojectBuildDir = newBuildDir.dir(project.name)
    project.layout.buildDirectory.set(newSubprojectBuildDir)

    // Ensure multidex + desugaring are applied globally
    plugins.withId("com.android.application") {
        configureAndroid()
    }
    plugins.withId("com.android.library") {
        configureAndroid()
    }
}

fun Project.configureAndroid() {
    extensions.findByName("android")?.let {
        val androidExt = it as com.android.build.gradle.BaseExtension
        androidExt.compileOptions.apply {
            sourceCompatibility = JavaVersion.VERSION_11
            targetCompatibility = JavaVersion.VERSION_11
            isCoreLibraryDesugaringEnabled = true
        }

        androidExt.defaultConfig.apply {
            multiDexEnabled = true
        }
    }

    dependencies {
        add("coreLibraryDesugaring", "com.android.tools:desugar_jdk_libs:2.0.3")
        add("implementation", "androidx.multidex:multidex:2.0.1")
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
