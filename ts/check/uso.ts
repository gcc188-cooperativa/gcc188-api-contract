// Verificação de compilação: garante que tipos-chave existem e que enums estão como no contrato.
import type { components, paths } from '../dist/index';

type Contrato = components['schemas']['Contrato'];
type Status = Contrato['status'];
const ok: Status = 'PENDENTE_APROVACAO';

type Aprovar = paths['/contratos/{id}/aprovacao']['post'];
type Erro = components['schemas']['ProblemDetail'];
const erro: Erro = { title: 'Conflito', status: 409, codigo_regra: 'RN06' };

export { ok, erro };
export type { Aprovar };
