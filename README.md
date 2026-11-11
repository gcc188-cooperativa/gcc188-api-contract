# gcc188-api-contract

Fonte de verdade da API REST da cooperativa de transportes (D06, _contract-first_): recursos, esquemas, erros e segurança em **OpenAPI 3.1**. Backend e front **não copiam** o documento; consomem **pacotes versionados** gerados aqui (D07).

| Artefato publicado (GitHub Packages, mesma versão) | Conteúdo                                                           | Consumidor                            |
| -------------------------------------------------- | ------------------------------------------------------------------ | ------------------------------------- |
| Maven `br.ufla.gcc188:cooperativa-api-contract`    | DTOs e interfaces Spring (`ContratosApi`, …), modo `interfaceOnly` | backend implementa as interfaces      |
| npm `@<org>/api-contract`                          | `dist/openapi.yaml`, `dist/openapi.json` e tipos TS                | front gera hooks, Zod e MSW com Orval |

## Estrutura

```text
openapi/
├── openapi.yaml            # entrada: info, servers, security, tags e mapa rota → arquivo
├── paths/                  # um arquivo por recurso (usuarios, contratos, pagamentos, ...)
└── components/
    ├── schemas/            # DTOs e enumerações, por módulo
    ├── parameters/         # Id, Page, Size, Sort
    ├── responses/          # 400, 401, 403, 404, 409 e 422 (application/problem+json)
    └── examples/           # exemplos de erro (usados por Prism e MSW)
java/                       # projeto Gradle: gera e publica DTOs e interfaces
ts/                         # empacota o documento e gera tipos TypeScript
scripts/                    # mock-smoke.sh, check-breaking.sh
docs/convencoes.md          # convenções do contrato
.github/workflows/          # ci, governance, release
```

Cobertura: 35 rotas, 47 operações e 53 esquemas (seção 10 da especificação e os acréscimos da Δ07: `/auth/refresh`, `/auth/logout`, `/auth/me`, `/usuarios/{id}/redefinicao-senha`).

## Uso diário

```bash
npm ci                 # Redocly, Spectral, Prism, Prettier, commitlint, lefthook
npm run lint           # Spectral (sobre o bundle) + Redocly + Prettier
npm run bundle         # build/openapi.yaml (arquivo único)
npm run mock           # mock do Prism em http://127.0.0.1:4010
npm run mock:smoke     # sobe o Prism e confere que os exemplos respondem e validam
npm run breaking       # oasdiff contra a última tag (requer o binário oasdiff)
(cd ts && npm ci && npm run build && npm run typecheck)
(cd java && gradle build)
```

> O Prism serve na raiz (ignora o prefixo relativo `/api/v1` de `servers`). No sistema integrado, o Caddy roteia `/api/*` ao backend (`gcc188-infra`).

## Fluxo de trabalho

- **Ramos:** _trunk-based_ protegido (D04): `master` + ramos curtos `feat/*` e `fix/*` (até 2 dias úteis), PR com revisão e verificações obrigatórias, _squash merge_.
- **Commits:** Conventional Commits com o módulo como escopo, por exemplo `feat(contratos): aprovar contrato e gerar pagamentos (RF-CTR-04)`. Escopos válidos em `commitlint.config.cjs`.
- **Versão:** SemVer via Release Please. Cada push em `master` abre/atualiza o PR de release (`CHANGELOG.md`, `java/gradle.properties`, `ts/package.json`, `info.version`). Ao integrá-lo, cria-se a tag `vX.Y.Z` e os dois pacotes são publicados no mesmo workflow.
- **Antes da 1.0.0** mudança incompatível é _minor_; **depois**, remover/renomear campo, torná-lo obrigatório ou mudar tipo é _major_ e exige `!` no título do PR (`feat(contratos)!: ...`). Remoção passa antes por `deprecated: true` por ao menos uma _minor_.

## Verificações do CI (bloqueiam o PR)

| Job          | O que garante                                                                                                                        |
| ------------ | ------------------------------------------------------------------------------------------------------------------------------------ |
| `lint`       | Spectral (`operationId` camelCase, `snake_case`, exemplos em recursos e erros, erros em `problem+json`), Redocly, Prettier, yamllint |
| `breaking`   | oasdiff contra a última tag (política acima)                                                                                         |
| `java`       | o gerador produz código que compila                                                                                                  |
| `typescript` | `tsc --noEmit` sobre os tipos gerados                                                                                                |
| `mock-smoke` | Prism sobe e as respostas de exemplo validam contra os esquemas                                                                      |
| `governance` | título do PR e commits no padrão                                                                                                     |

O teste do contrato contra a implementação (Schemathesis) roda no CI do backend.

## Consumo

**Backend (Gradle):** declare a versão em `gradle/libs.versions.toml` e implemente as interfaces geradas.

```kotlin
repositories { maven("https://maven.pkg.github.com/<org>/gcc188-api-contract") { credentials { username = ...; password = ... } } }
dependencies { implementation("br.ufla.gcc188:cooperativa-api-contract:<versão>") }
```

**Front (npm):** `.npmrc` com `@<org>:registry=https://npm.pkg.github.com`; o Orval lê `node_modules/@<org>/api-contract/dist/openapi.yaml`.

A leitura do GitHub Packages exige _token_ mesmo em repositórios públicos: no CI basta o `GITHUB_TOKEN`; localmente, um _token_ pessoal com `read:packages` (PD02).

## Java

- Gerador `spring` com `interfaceOnly`, `useSpringBoot4`, `useJackson3`, `useTags` (opções do OpenAPI Generator 7.16.0 em diante), toolchain Java 25.
- O **Gradle _wrapper_ não está versionado** (gerá-lo exige um Gradle instalado). No marco M0: `cd java && gradle wrapper --gradle-version 9.1.0` e versione `gradlew`, `gradlew.bat` e `gradle/wrapper/`. Até lá o CI usa o Gradle do `setup-gradle`.
- Fixe a versão do Spring Boot em `gradle/libs.versions.toml` (PD12).

## Pendências

- **PD01:** nome da organização; o escopo npm é definido no _release_ a partir do dono do repositório (`@org` em `ts/package.json` é _placeholder_).
- **PD02:** GitHub Packages (adotado) versus Maven Central/npmjs.
- **PD03:** `groupId` e pacote base Java.
