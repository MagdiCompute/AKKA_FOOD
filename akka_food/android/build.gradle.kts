allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Keep build output inside the android directory to avoid path-with-spaces
// issues in the Flutter Gradle plugin on Windows.
rootProject.layout.buildDirectory.value(rootProject.layout.projectDirectory.dir("build"))

subprojects {
    project.layout.buildDirectory.value(rootProject.layout.buildDirectory.get().dir(project.name))
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
