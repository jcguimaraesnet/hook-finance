---
status: draft
last_updated: YYYY-MM-DD
---

# Nome da regra / card / página

## Contexto

Por que essa regra/card/página existe. Qual problema resolve. Em que momento ela é exercida.

## Regras

1. Primeira regra autoritativa — escreva como afirmação, não como condicional vaga.
2. Segunda regra. Inclua fórmulas explícitas quando for cálculo (`valor = total / parcelas`).
3. Use sub-itens quando ajudar a leitura:
   - Caso A: …
   - Caso B: …

## Edge cases

- O que acontece quando `rows` é vazio?
- O que acontece quando o campo `X` é nulo/undefined/string vazia?
- Que acontece em mês sem nenhum dado de origem `Pix (contas)`?
- Limites numéricos (negativos, zero, valores muito altos).

## Implementações

- **PWA:** `web/src/core/<path>.ts`
- **Flutter:** `app/lib/core/<path>.dart`
- **Backend:** `apps-script/<file>.gs` (quando aplicável)

## Specs relacionadas

- [../rules/<x>.md](../rules/X.md)
- [../data/despesas-sheet.md](../data/despesas-sheet.md) (quando dependende do schema)
