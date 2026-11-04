// uCrop (package image_cropper, scan des bilans) n'est publié que sur JitPack.
// Les miroirs Aliyun / Huawei exposent son POM mais pas son .aar : on réserve
// donc ce groupe à JitPack et on l'exclut des miroirs.
val jitpackOnlyGroup = "com.github.Yalantis"

fun RepositoryHandler.medilinkRepositories() {
    maven {
        url = uri("https://jitpack.io")
        content { includeGroup(jitpackOnlyGroup) }
    }
    google { content { excludeGroup(jitpackOnlyGroup) } }
    mavenCentral { content { excludeGroup(jitpackOnlyGroup) } }
    maven {
        url = uri("https://maven.aliyun.com/repository/public")
        content { excludeGroup(jitpackOnlyGroup) }
    }
    maven {
        url = uri("https://repo.huaweicloud.com/repository/maven/")
        content { excludeGroup(jitpackOnlyGroup) }
    }
}

allprojects {
    repositories { medilinkRepositories() }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)

    repositories { medilinkRepositories() }
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
