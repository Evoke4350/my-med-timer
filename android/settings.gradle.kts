pluginManagement {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

dependencyResolutionManagement {
    repositories {
        google()
        mavenCentral()
    }
}

rootProject.name = "MyMedTimer"

include(":app")
include(":math")
include(":core:domain")
include(":core:data")
include(":core:common")
include(":feature:medlist")
include(":feature:addedit")
include(":feature:history")
include(":feature:settings")
