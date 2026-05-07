---
status: stable
last_updated: 2026-05-07
---

# Card to person — mapping de finais de cartão

Os 4 dígitos finais do cartão (col H) identificam o titular. Constante única.

## Contexto

A notificação do banco vem com final do cartão; o titular não. Mapeamento estático em `apps-script/shared/Constants.gs`. Hoje **não é usado para nenhuma regra de UI** — é só metadata informativa. Mas existe potencial uso futuro (Flutter pode mostrar avatar do titular ao lado da despesa, ou agrupar por titular).

## Regras

```js
const CARDS = {
  "1018": "Julio",
  "9727": "Julio",
  "4750": "Dani",
  "0784": "Dani",
};
```

`cardToPerson(last4) → "Julio" | "Dani" | null`:

- Lookup direto na constante. Sem fallback heurístico.
- `last4` desconhecido → `null` (ou `undefined`/`""` em JS — implementação escolhe).

A constante é **fonte da verdade** desse mapping. Adicionar/remover cartão = editar essa constante (e propagar para PWA/Flutter quando essas codebases consumirem).

## Edge cases

- **`last4` com tamanho diferente de 4:** ainda funciona se a chave bater literalmente. Notificações estranhas (`"final 1018A"`) não casam.
- **Cartão extra do mesmo titular:** acrescentar nova chave apontando pro nome.
- **Cartão de terceiro** (ex.: pais visitando): hoje seria mapeado como "(desconhecido)". Pode-se acrescentar um terceiro nome (ex.: `"Alzira"`) — `Person` em código tipa apenas Julio/Dani, então essa expansão pediria revisar tipos.

## Implementações

- **Backend (autoritativo):** [apps-script/shared/Constants.gs](../../../apps-script/shared/Constants.gs) — constante `CARDS`.
- **PWA atual:** N/A (não usado). Quando usar: `web/src/core/rules/cardToPerson.ts` (Onda 2/futuro).
- **Flutter:** se usado, `app/lib/core/rules/card_to_person.dart`.

## Specs relacionadas

- [../data/despesas-sheet.md](../data/despesas-sheet.md) — col H (`Cartão`)
- [../api/webhook.md](../api/webhook.md)
