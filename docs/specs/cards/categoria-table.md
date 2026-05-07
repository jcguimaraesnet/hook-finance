---
status: stable
last_updated: 2026-05-07
---

# CategoriaTable — Cartão compartilhado por categoria

Tabela mostrando, para o mês atual, despesas de Cartão agrupadas por `categoria`, com colunas Cheio, Compart. (metade) e %.

## Contexto

Aparece na aba "Categoria" de Consulta. Foco em entender a composição dos gastos compartilhados — quanto cada categoria pesa no Cartão.

## Regras

### Inputs

- `rows`: `Row[]` do mês atual.

### Filtragem

- Considera **só** linhas com `origem === "Cartão"`.
- **Não filtra por `rateio`**. Categorias incluem cartão pessoal (Julio/Dani) também — a coluna "Compart." sinaliza visualmente quem é compartilhado.

### Agregação

```
byCat[r.categoria || "(sem categoria)"] += r.valor
```

`totalCheio = Σ byCat[*]`.

### Linhas (ordenadas por `cheio` desc)

| Coluna | Conteúdo |
|---|---|
| Categoria | nome (`categoria` ou `"(sem categoria)"`) |
| Valor (R$) | `formatMoney(cheio)` |
| Compart. (R$) | `formatMoney(cheio / 2)` — exceto se `cat === "Pessoal"` → `"—"` |
| % | `formatPct(cheio / totalCheio)` |

Linha final **Total Geral**:
- Valor: `formatMoney(totalCheio)`
- Compart.: `"—"`
- %: `100%`

### Por que `Pessoal` não tem Compart.

Categoria "Pessoal" no contexto de Cartão é convenção: "essa compra foi pessoal" (mesmo no cartão compartilhado). Mostrar "metade" não faz sentido. UI exibe `—`.

## Edge cases

- **Mês sem Cartão:** tabela só com "Total Geral 0,00 / — / —".
- **`categoria` vazio:** vai para o bucket `"(sem categoria)"`.
- **`valor` negativo:** soma normal; aparece no bucket. Compart. = `valor / 2` (também negativo).

## Implementações

- **PWA atual:** [web/src/components/CategoriaTable.tsx](../../../web/src/components/CategoriaTable.tsx)
- **Após Onda 2:** sem mudança lógica grande; pode usar `BUCKET_ORDER` de `core/constants.ts` se útil. A regra "filtrar Cartão" é simples e pode permanecer inline OU virar um helper `core/filters.ts` se aparecer em mais de 3 lugares.
- **Flutter:** `app/lib/widgets/categoria_table.dart` (Onda 5).

## Specs relacionadas

- [../pages/consulta.md](../pages/consulta.md)
- [rateio-chart.md](rateio-chart.md) — variante mostrando Cartão por rateio em vez de categoria
