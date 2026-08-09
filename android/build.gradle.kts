allprojects {
    repositories {
        google()
        mavenCentral()
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

// mapbox_maps_flutter 2.25.0 hardcodes compileSdk 35, but other plugins
// (flutter_plugin_android_lifecycle via geocoding) require 36. Bump just that
// module so the AAR metadata check passes.
subprojects {
    afterEvaluate {
        if (project.name == "mapbox_maps_flutter") {
            project.extensions
                .findByType(com.android.build.gradle.BaseExtension::class.java)
                ?.compileSdkVersion(36)
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
