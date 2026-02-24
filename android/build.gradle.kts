allprojects {
    repositories {
        google()
        mavenCentral()
    }

    // Timeout සහ caching ප්‍රශ්න සඳහා නිවැරදි කළ Kotlin syntax එක
    configurations.all {
        resolutionStrategy {
            cacheDynamicVersionsFor(0, "seconds")
            cacheChangingModulesFor(0, "seconds")
        }
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}