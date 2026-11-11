// Empacota o OpenAPI em um único arquivo (YAML e JSON) e gera os tipos TypeScript.
import { execFileSync } from 'node:child_process';
import { mkdirSync, writeFileSync } from 'node:fs';

const entry = '../openapi/openapi.yaml';
mkdirSync('dist', { recursive: true });
const run = (cmd, args) => execFileSync(cmd, args, { stdio: 'inherit' });

run('npx', ['redocly', 'bundle', entry, '-o', 'dist/openapi.yaml']);
run('npx', ['redocly', 'bundle', entry, '--ext', 'json', '-o', 'dist/openapi.json']);
run('npx', ['openapi-typescript', 'dist/openapi.yaml', '-o', 'dist/index.d.ts']);
writeFileSync('dist/index.js', '// Somente tipos: use `import type { components } from "@org/api-contract"`.\nexport {};\n');
