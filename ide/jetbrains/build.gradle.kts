// JetBrains plugin scaffold. Run: ./gradlew runIde to dev-launch.
plugins {
    id("org.jetbrains.intellij") version "1.17.3"
    kotlin("jvm") version "1.9.22"
}

group = "app.vibeclone"
version = "0.1.0"

repositories { mavenCentral() }

intellij {
    version.set("2024.1")
    type.set("IC")
    plugins.set(listOf())
}

tasks.patchPluginXml {
    sinceBuild.set("241")
    untilBuild.set("251.*")
}
