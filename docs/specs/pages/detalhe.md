---
status: stable
last_updated: 2026-05-07
---

# Detalhe — despesas pessoais por pessoa

Página que lista despesas de **Cartão pessoal** (não compartilhadas) do mês corrente, agrupadas por pessoa, em accordions colapsáveis.

## Contexto

Útil para revisar o que cada um gastou no cartão pessoal — separado da despesa compartilhada que vai para o acerto. Não inclui Pix/Contas (essas têm seu lugar em Acerto).

## Regras

### Inputs

Lê `monthData(currentMonth)`. Não chama outros endpoints.

### Filtragem

- `r.origem === "Cartão"` (só Cartão).
- `r.rateio !== ""` E `r.rateio !== "Metade"` (exclui sem rateio e compartilhado).

### Agregação

Agrupa por `r.rateio`. Cada grupo:

- `total = Σ r.valor` (cheio, não dividido).
- `items = Row[]` daquele rateio.

### Ordem dos grupos

Ordem preferida: `["Julio", "Dani", "Alzira"]`. Outros rateios (raros) entram depois em ordem alfabética.

```ts
const ordered = [...PREFERRED_ORDER, ...others.sort()].filter((p) => byPerson[p]);
```

### Render

Cada grupo é um `<details>` (accordion) colapsado:

- **Summary:** nome (`Julio`/`Dani`/...) + total `R$ X` à direita.
- **Body** (quando expandido): tabela com colunas Data | Descrição | Valor.
  - Itens ordenados por `dataRef` **descendente** (mais recente primeiro).

### Loading / vazio

- Loading: 3 skeletons.
- Sem despesas pessoais: mensagem `"Sem despesas pessoais neste mês."`.

## Edge cases

- **Mês sem nenhuma despesa Cartão pessoal:** mostra mensagem de vazio.
- **Pessoa só com despesas compartilhadas no mês:** não aparece (filtra `rateio === "Metade"`).
- **Rateio com valor diferente de Julio/Dani/Alzira:** entra na seção `others`, ordem alfabética.
- **`dataRef` sem horário:** `localeCompare` ainda funciona (ordena por string).

## Implementações

- **PWA:** [web/src/pages/DetalhePage.tsx](../../../web/src/pages/DetalhePage.tsx)
- **Após Onda 2:** `PREFERRED_ORDER` move para `core/constants.ts`. Filtro fica inline (regra simples, sem reuso fora dessa página).
- **Flutter:** `app/lib/features/detalhe/` (Onda 5). Usar `ExpansionTile` para o accordion.

## Specs relacionadas

- [../data/despesas-sheet.md](../data/despesas-sheet.md) — cols E (origem), G (rateio), B (dataRef)
- [../responsive/breakpoints.md](../responsive/breakpoints.md)
