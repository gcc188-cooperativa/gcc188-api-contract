# Convenções do contrato

Mantém a seção 10.1 da especificação (base `/api/v1`, comandos de transição por `POST` em sub-recurso, códigos 200, 201, 204, 400, 401, 403, 404, 409 e 422) e acrescenta:

| Tema               | Convenção                                                                                                                                                  |
| ------------------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Formato            | OpenAPI 3.1; um arquivo por recurso em `paths/`; esquemas em `components/schemas/<módulo>.yaml`                                                            |
| Nomes (D38)        | Campos JSON em `snake_case`, iguais às colunas. `operationId` em camelCase com verbo e recurso. Uma _tag_ por módulo                                       |
| Dinheiro (D39)     | `number` com `multipleOf: 0.01`; o front não faz aritmética monetária                                                                                      |
| Datas              | `date` para vencimentos e vigência; `date-time` em UTC para instantes (RNF-14)                                                                             |
| Enums              | Maiúsculas, iguais aos valores do banco (`PENDENTE_APROVACAO`)                                                                                             |
| Lista paginada     | `{ content, page, size, total_elements, total_pages }`; `page` inicia em 0, `size` padrão 20 e máximo 100; `sort` só com campos listados na operação       |
| Erros              | `application/problem+json` (RFC 9457) + `campos_invalidos`, `codigo_regra`, `correlation_id`                                                               |
| Segurança          | `cookieAuth` (`ACCESS_TOKEN`); escrita autenticada exige `X-XSRF-TOKEN` (`csrfHeader`). `login` e `refresh` não exigem CSRF; `refresh` usa `refreshCookie` |
| Concorrência (D13) | `versao` nas leituras de usuário, contrato, pagamento e despesa; obrigatória em `PUT`; divergência → 409                                                   |
| Papéis             | Cada operação declara `x-papeis` e os lista na descrição                                                                                                   |
| Exemplos           | Todo recurso e todo erro têm exemplo (verificado pelo Spectral)                                                                                            |

## Mapa rota → arquivo

`openapi.yaml` referencia cada rota como `paths/<recurso>.yaml#/<chave>`; a chave é a rota sem a barra inicial, com `/` → `_`, `{id}` → `id` e `-` → `_` (`/contratos/{id}/aprovacao` → `contratos_id_aprovacao`). Chaves simples evitam ponteiros JSON escapados, que o Spectral não resolve.

## Como adicionar um recurso

1. Esquemas em `components/schemas/<módulo>.yaml` (com `examples`) e `$ref` em `components.schemas` de `openapi.yaml`.
2. Operações em `paths/<recurso>.yaml` e a rota em `paths:` de `openapi.yaml`.
3. `npm run lint && npm run mock:smoke`; PR `feat(<módulo>): ...`.
