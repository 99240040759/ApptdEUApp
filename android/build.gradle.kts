allprojects {
    repositories {
        google()
        mavenCentral()
    }
    // Force stable Kotlin artifacts — prevents unreleased 2.2.x being requested by plugins
    configurations.all {
        resolutionStrategy.force(
            "org.jetbrains.kotlin:kotlin-stdlib:2.1.0",
            "org.jetbrains.kotlin:kotlin-stdlib-jdk7:2.1.0",
            "org.jetbrains.kotlin:kotlin-stdlib-jdk8:2.1.0",
            "org.jetbrains.kotlin:kotlin-reflect:2.1.0",
        )
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
// gradle.afterProject fires after EACH project's own build.gradle is evaluated
// — overrides any hardcoded compileSdk regardless of evaluation order
gradle.afterProject {
    extensions.findByType<com.android.build.gradle.LibraryExtension>()?.compileSdk = 36
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
