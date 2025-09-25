buildscript {
    repositories {
        google()          // Pour les plugins Google (ex. com.android.tools.build:gradle)
        mavenCentral()    // Pour les autres dépendances de buildscript
    }
    dependencies {
        classpath("com.android.tools.build:gradle:8.1.0")       // Ex. Android Gradle Plugin
        classpath("com.google.gms:google-services:4.3.15")      // Plugin Google Services
    }
}

// Vos blocs existants
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
    evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

