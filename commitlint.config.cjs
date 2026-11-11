// Conventional Commits com o módulo como escopo (Δ01), ex.: feat(contratos): aprovar contrato (RF-CTR-04)
module.exports = {
  extends: ['@commitlint/config-conventional'],
  rules: {
    'scope-enum': [2, 'always', [
      'autenticacao', 'usuarios', 'cooperandos', 'clientes', 'contratos', 'pagamentos',
      'despesas', 'relatorios', 'painel', 'comum', 'java', 'ts', 'ci', 'deps', 'docs',
    ]],
    'header-max-length': [2, 'always', 100],
  },
};
