# gcc188-api-contract

Fonte de verdade da API REST da cooperativa de transportes (D06, _contract-first_): recursos, esquemas, erros e segurança em **OpenAPI 3.1**. Backend e front **não copiam** o documento; consomem **pacotes versionados** gerados aqui e publicados no **GitHub Packages** da organização Cooperativa, `gcc188-cooperativa` no GitHub (D07).

| Artefato publicado (GitHub Packages, mesma versão) | Conteúdo                                                           | Consumidor                            |
| -------------------------------------------------- | ------------------------------------------------------------------ | ------------------------------------- |
| Maven `br.ufla.gcc188:cooperativa-api-contract`    | DTOs e interfaces Spring (`ContratosApi`, …), modo `interfaceOnly` | backend implementa as interfaces      |
| npm `@gcc188-cooperativa/api-contract`             | `dist/openapi.yaml`, `dist/openapi.json` e tipos TS                | front gera hooks, Zod e MSW com Orval |

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

## Fluxo de trabalho (tarefa #21)

- **Ramos:** _trunk-based_ protegido (D04): `master` + ramos curtos `feat/*`, `fix/*` e `docs/*` (até 2 dias úteis), PR com revisão e verificações obrigatórias, _squash merge_.
- **Commits:** _Conventional Commits_ `tipo(escopo): descrição (RF-xxx-NN)`; escopos válidos em `commitlint.config.cjs`. Ex.: `feat(contratos): aprovar contrato e gerar pagamentos (RF-CTR-04)`.
- **Pastas:** fonte OpenAPI em `openapi/`, geradores em `java/` e `ts/`, convenções em `docs/convencoes.md`. Contrato e artefatos gerados versionados aqui; requisitos e design ficam em `gcc188-docs`.
- **`.gitignore`:** ignora `node_modules/`, `build/`, `ts/dist/`, `java/build/`, `java/.gradle/`, `java/.idea/`, `*.log` e `.env`; saídas de geração e credenciais não entram no Git.
- **Versão:** SemVer via Release Please. Cada push em `master` abre/atualiza o PR de release (`CHANGELOG.md`, `java/gradle.properties`, `ts/package.json`, `info.version`). Ao integrá-lo, cria-se a tag `vX.Y.Z` e os dois pacotes são publicados no GitHub Packages no mesmo workflow.
- **Compatibilidade:** antes da 1.0.0 mudança incompatível é _minor_; depois, remover/renomear campo, torná-lo obrigatório ou mudar tipo é _major_ e exige `!` no título do PR (`feat(contratos)!: ...`). Remoção passa antes por `deprecated: true` por ao menos uma _minor_.
- **Verificação:** `lefthook` roda `pre-commit` (Spectral/Prettier) e `commit-msg` (commitlint); `governance` valida título de PR e commits no CI.

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

Os pacotes são publicados **somente no GitHub Packages** (`maven.pkg.github.com` e `npm.pkg.github.com`); não há publicação no Maven Central nem no npmjs.

**Backend (Gradle):** declare a versão em `gradle/libs.versions.toml` e implemente as interfaces geradas. Coordenadas: `groupId` `br.ufla.gcc188`, `artifactId` `cooperativa-api-contract`, pacote base `br.ufla.gcc188.cooperativa.api`.

```kotlin
repositories { maven("https://maven.pkg.github.com/gcc188-cooperativa/gcc188-api-contract") { credentials { username = ...; password = ... } } }
dependencies { implementation("br.ufla.gcc188:cooperativa-api-contract:<versão>") }
```

**Front (npm):** `.npmrc` com `@gcc188-cooperativa:registry=https://npm.pkg.github.com`; o Orval lê `node_modules/@gcc188-cooperativa/api-contract/dist/openapi.yaml`.

A leitura do GitHub Packages exige _token_ mesmo em repositórios públicos: no CI basta o `GITHUB_TOKEN`; localmente, um _token_ pessoal com `read:packages`.

## Java

- Gerador `spring` com `interfaceOnly`, `useSpringBoot4`, `useJackson3`, `useTags` (opções do OpenAPI Generator 7.16.0 em diante), toolchain Java 25. DTOs e interfaces em `br.ufla.gcc188.cooperativa.api` (e subpacotes `.model` e `.invoker`).

## Decisões registradas

- **PD01:** organização Cooperativa (`gcc188-cooperativa` no GitHub); o escopo npm é `@gcc188-cooperativa/api-contract`, fixo em `ts/package.json` (não é mais derivado do dono do repositório no release).
- **PD02:** publicação exclusivamente no GitHub Packages — Maven em `maven.pkg.github.com` e npm em `npm.pkg.github.com`; não há publicação no Maven Central nem no npmjs.
- **PD03:** `groupId` `br.ufla.gcc188`, `artifactId` `cooperativa-api-contract` e pacote base Java `br.ufla.gcc188.cooperativa.api`, conforme `java/build.gradle.kts`.

## Pendências

- **PD12:** confirmar a linha do Spring Boot fixada em `java/gradle/libs.versions.toml` (`4.0.0`) no marco M0.
- **Wrapper Gradle:** não está versionado. No marco M0: `cd java && gradle wrapper --gradle-version 9.1.0` e versionar `gradlew`, `gradlew.bat` e `gradle/wrapper/`. Até lá o CI usa o Gradle do `setup-gradle`.
