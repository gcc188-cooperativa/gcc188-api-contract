#!/usr/bin/env bash
# Sobe o Prism com o documento empacotado e confere que os exemplos respondem e validam (--errors).
set -euo pipefail
cd "$(dirname "$0")/.."
PORT="${PRISM_PORT:-4010}"; BASE="http://127.0.0.1:${PORT}"  # o Prism ignora o prefixo relativo /api/v1 e serve na raiz
npm run --silent bundle
npx --no-install prism mock -h 127.0.0.1 -p "$PORT" --errors build/openapi.yaml >build/prism.log 2>&1 &
PID=$!; trap 'kill $PID 2>/dev/null || true' EXIT
for _ in $(seq 1 60); do curl -s -o /dev/null "http://127.0.0.1:${PORT}/" && break; sleep 0.5; done
fail=0
check() { # método rota status-esperado
  local code; code=$(curl -s -o /dev/null -w '%{http_code}' -X "$1" "${BASE}$2" \
    -H 'Cookie: ACCESS_TOKEN=x; XSRF-TOKEN=x' -H 'X-XSRF-TOKEN: x' -H 'Content-Type: application/json' ${4:+-d "$4"})
  if [ "$code" != "$3" ]; then echo "FALHA: $1 $2 -> $code (esperado $3)"; fail=1; else echo "ok: $1 $2 -> $code"; fi
}
PER='data_inicio=2026-12-01&data_fim=2026-12-31'
check GET /auth/me 200
check GET /usuarios 200
check GET /usuarios/1 200
check GET /cooperandos 200
check GET /cooperandos/1 200
check GET "/cooperandos/1/extrato?${PER}" 200
check GET /clientes 200
check GET /contratos 200
check GET /contratos/1 200
check GET /contratos/1/pagamentos 200
check GET /pagamentos 200
check GET /despesas 200
check GET /despesas/totais 200
check GET "/relatorios/resumo-financeiro?${PER}" 200
check GET /relatorios/inadimplencia 200
check GET /painel/indicadores 200
check POST /contratos/1/aprovacao 200
check POST /pagamentos/1/baixa 200 '{"data_baixa":"2026-12-10"}'
exit $fail
