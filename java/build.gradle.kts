// Gera e publica DTOs e interfaces Spring (interfaceOnly) a partir do documento OpenAPI empacotado (D07).
// O backend implementa as interfaces nos controladores; o compilador acusa divergência com o contrato.
plugins {
    `java-library`
    `maven-publish`
    alias(libs.plugins.openapi.generator)
}

group = "br.ufla.gcc188"
// A versão vem de gradle.properties (marcada para o Release Please).

java {
    toolchain { languageVersion = JavaLanguageVersion.of(25) }
    withSourcesJar()
}

repositories { mavenCentral() }

dependencies {
    api(platform(libs.spring.boot.dependencies))
    api(libs.spring.web)
    api(libs.jakarta.validation)
    api(libs.jackson.annotations)
    api(libs.jakarta.annotation)
}

val bundled = rootProject.layout.projectDirectory.file("../build/openapi.yaml")
val generatedDir = layout.buildDirectory.dir("generated")

// O documento empacotado é produzido pelo Redocly (npm run bundle, na raiz do repositório).
val bundleContract by tasks.registering(Exec::class) {
    workingDir = rootProject.projectDir.parentFile
    commandLine("npm", "run", "--silent", "bundle")
    inputs.dir(rootProject.projectDir.parentFile.resolve("openapi"))
    outputs.file(bundled)
}

openApiGenerate {
    generatorName.set("spring")
    inputSpec.set(bundled.asFile.absolutePath)
    outputDir.set(generatedDir.get().asFile.absolutePath)
    apiPackage.set("br.ufla.gcc188.cooperativa.api")
    modelPackage.set("br.ufla.gcc188.cooperativa.api.model")
    invokerPackage.set("br.ufla.gcc188.cooperativa.api.invoker")
    generateApiTests.set(false)
    generateModelTests.set(false)
    configOptions.set(mapOf(
        "interfaceOnly" to "true",          // só DTOs e interfaces; sem implementação
        "useSpringBoot4" to "true",         // opções disponíveis desde o gerador 7.16.0
        "useJackson3" to "true",
        "useTags" to "true",                // uma interface por tag (ContratosApi, ...)
        "skipDefaultInterface" to "true",
        "useBeanValidation" to "true",
        "openApiNullable" to "false",
        "documentationProvider" to "none",
        "annotationLibrary" to "none",
        "dateLibrary" to "java8",
        "useResponseEntity" to "true",
        "hideGenerationTimestamp" to "true",
        "sortParamsByRequiredFlag" to "true",
    ))
}

tasks.openApiGenerate { dependsOn(bundleContract) }

sourceSets.main { java.srcDir(generatedDir.map { it.dir("src/main/java") }) }
tasks.compileJava { dependsOn(tasks.openApiGenerate) }
tasks.named("sourcesJar") { dependsOn(tasks.openApiGenerate) }

publishing {
    publications {
        create<MavenPublication>("contract") {
            artifactId = "cooperativa-api-contract"
            from(components["java"])
            pom {
                name.set("Cooperativa API contract")
                description.set("DTOs e interfaces Spring gerados do contrato OpenAPI da cooperativa.")
            }
        }
    }
    repositories {
        maven {
            name = "GitHubPackages"
            // GITHUB_REPOSITORY = <org>/gcc188-api-contract, definido pelo GitHub Actions
            url = uri("https://maven.pkg.github.com/${System.getenv("GITHUB_REPOSITORY") ?: "ORG/gcc188-api-contract"}")
            credentials {
                username = System.getenv("GITHUB_ACTOR")
                password = System.getenv("GITHUB_TOKEN")
            }
        }
        // Instalação local para testar no backend: ./gradlew publishToMavenLocal
    }
}
