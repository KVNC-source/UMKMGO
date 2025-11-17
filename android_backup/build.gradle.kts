// Root project Gradle file (Kotlin DSL).
// Flutter tidak butuh konfigurasi khusus di level root.

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
