#!/usr/bin/env bash
# Compara o contrato atual com o da última tag (oasdiff) e falha em mudança incompatível (D08).
# Exceções: antes da 1.0.0 (mudança incompatível = minor, apenas avisa) ou PR com `!` no título.
# Requer: oasdiff no PATH, git com tags, npm install executado. Variável opcional: PR_TITLE.
set -euo pipefail
cd "$(dirname "$0")/.."
TAG="$(git describe --tags --abbrev=0 --match 'v*' 2>/dev/null || true)"
if [ -z "$TAG" ]; then echo "Sem tag anterior: nada a comparar."; exit 0; fi
BASE_DIR="$(mktemp -d)"; trap 'rm -rf "$BASE_DIR"' EXIT
git worktree add --detach "$BASE_DIR/base" "$TAG" >/dev/null
( cd "$BASE_DIR/base" && ln -s "$OLDPWD/node_modules" node_modules && npx --no-install redocly bundle openapi/openapi.yaml -o "$BASE_DIR/base.yaml" >/dev/null )
npm run --silent bundle
VERSION="${TAG#v}"; MAJOR="${VERSION%%.*}"
if oasdiff breaking "$BASE_DIR/base.yaml" build/openapi.yaml --fail-on ERR; then
  echo "Nenhuma mudança incompatível em relação a $TAG."
elif [ "$MAJOR" = "0" ]; then
  echo "AVISO: mudança incompatível antes da 1.0.0 (permitida, registre no changelog)."
elif [[ "${PR_TITLE:-}" =~ ^[a-z]+(\([^)]*\))?! ]]; then
  echo "Mudança incompatível declarada com '!' no título do PR; será uma versão major."
else
  echo "ERRO: mudança incompatível sem '!' no título do PR (ex.: feat(contratos)!: ...)."; exit 1
fi
