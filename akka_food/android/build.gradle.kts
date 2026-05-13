allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// When building from a path without spaces (e.g. C:\AkkaFood-Dev), the default
// build directory works fine. The custom build directory override is only needed
// when building from a path with spaces.
// rootProject.layout.buildDirectory.value(rootProject.layout.projectDirectory.dir("build"))

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
