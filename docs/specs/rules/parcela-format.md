---
status: stable
last_updated: 2026-05-07
---

# Parcela — formato e helpers

A col I (Parcela) da planilha guarda compras parceladas como string `"1/N"`, onde `N` é o total de parcelas. Vazio = à vista.

## Contexto

A planilha registra **uma única linha** por compra parcelada (a "1/N"). Não há linhas separadas por parcela. O modal de Lançamento permite editar `N` (stepper); a "parcela atual" é sempre `1` por convenção. UIs que mostram o badge "1/N" leem essa string verbatim. Cálculos como "total da compra original" são derivados.

## Regras

### Formato

- Vazio (`""`) → compra à vista.
- `"1/N"` onde `N >= 2` → compra parcelada em N vezes; esta linha representa a 1ª parcela.
- A 1ª parte (`"1/"`) é fixa; só o total é editável.
- Storage como string (não número). Backend força `setNumberFormat("@")` na célula para impedir Sheets auto-parsear como data.

### Helpers

`parcelaTotal(p) → number`:

1. Se `p == null` ou `p === ""`, retorna `1`.
2. Se `String(p)` contém `"/"`, retorna `parseInt(parts[1], 10) || 1`.
3. Senão (formato legado, número solo), retorna `parseInt(String(p), 10) || 1`.

`isParcelado(p) → boolean`:

- Retorna `String(p ?? "").trim() !== ""`.

### Total da compra (no modal de edição)

Quando o modal abre uma entry parcelada:

- `originalTotal = entry.valor * parcelaTotal(entry.parcela)`.
- Stepper altera `parcela` (1..99). Ao mudar:
  - `valor = originalTotal / parcela` (rebalanceia para manter total constante).
- Se o usuário edita `valor` manualmente:
  - `originalTotal = valor * parcela` (recalibra com base no novo input).

### Save format (no modal)

- Se `parcela > 1`: grava `"1/${parcela}"`.
- Se `parcela === 1`: grava `""` (à vista).

## Edge cases

- **`p = "3"` (legado, número solo):** `parcelaTotal` retorna `3`. Entrada existente continua válida; modal renderiza como `3x` no stepper. Save converte para formato `"1/3"`.
- **`p = "3/0"` ou `"3/"`:** `parcelaTotal` cai no `parseInt("0", 10) || 1 = 1` (pelo `|| 1`). Tratamento defensivo; não deveria acontecer.
- **`parcela < 1` no stepper:** clamp em `1`. `parcela > 99`: clamp em `99`.
- **`valor` cresce ao reduzir parcelas:** esperado. Ex.: 30,00 em 3x → 10/parc; reduz para 1x → 30,00. Total constante.
- **Display do badge na lista:** mostra a string verbatim (`"1/3"`). Se `parcelaTotal > 1` mas `parcela === ""` (não acontece), não renderizar o badge.

## Implementações

- **Helpers PWA atual:** [web/src/utils/format.ts:33-44](../../../web/src/utils/format.ts) (move para `web/src/core/rules/parcela.ts` na Onda 2).
- **Modal logic:** [web/src/components/EditModal.tsx:25-67](../../../web/src/components/EditModal.tsx) — math do `originalTotalRef`.
- **Backend write:** [apps-script/dashboard/Dashboard.gs:267-269](../../../apps-script/dashboard/Dashboard.gs) — `setNumberFormat("@")`.
- **Flutter:** `app/lib/core/rules/parcela.dart` (Onda 4). Implementar mesma math no widget de edit (Onda 5).

```ts
// Reference impl
export function parcelaTotal(p: unknown): number {
  if (p == null || p === "") return 1;
  const s = String(p).trim();
  if (s.indexOf("/") !== -1) return parseInt(s.split("/")[1], 10) || 1;
  return parseInt(s, 10) || 1;
}

export function isParcelado(p: unknown): boolean {
  return String(p ?? "").trim() !== "";
}
```

## Specs relacionadas

- [../data/despesas-sheet.md](../data/despesas-sheet.md) — col I
- [../pages/lancamento.md](../pages/lancamento.md) — modal de edição
- [../api/endpoints.md](../api/endpoints.md) — `updateEntry.fields.parcela` format
