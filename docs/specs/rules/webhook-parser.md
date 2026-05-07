---
status: stable
last_updated: 2026-05-07
---

# Webhook parser — `PURCHASE_RE`

Extrai descrição, valor, data, hora e final do cartão da string de notificação que o Tasker/IFTTT manda como `text`.

## Contexto

A notificação do banco/cartão tem formato relativamente fixo. Uma única regex captura cinco grupos. Se a notificação muda (banco atualiza app), a regex precisa ser ajustada — esta spec é o único lugar que documenta o formato esperado.

## Regras

### Regex

```js
const PURCHASE_RE =
  /Compra.+?final\s+(\d+),.+?R\$\s*(-?[\d.,]+),.+?em\s+(\d{2}\/\d{2}\/\d{2,4}),.+?(\d{2}:\d{2}),\s*em\s+(.+?),\s*aprovada/i;
```

Grupos:

| # | Conteúdo | Exemplo |
|---|----------|---------|
| 1 | `cardLast4` | `1018` |
| 2 | `value` (BR string, antes de parse) | `89,50` |
| 3 | `refDate` | `03/04/26` ou `03/04/2026` |
| 4 | `refTime` | `14:32` |
| 5 | `description` (até `, aprovada`) | `MERCADO ABC` |

### Pós-processamento

- `refDate`: se ano de 2 dígitos (`26`), `normalizeDate_` prepende `"20"` → `"2026"`. Resultado canônico: `"DD/MM/YYYY"`.
- `value`: passa por `parseBrazilNumber_` → remove `.` (milhares), troca `,` por `.`, faz `parseFloat`. `NaN` → `""`.
- `description`: `.trim()`.
- `refTime`: usado verbatim (`"HH:MM"`).
- `cardLast4`: usado verbatim (string com dígitos; pode ter mais de 4 se a notificação variar).

### Composição em `dataRef`

`refDateTime = refTime ? refDate + " " + refTime : refDate`. Vai para col B da planilha.

### Falha de match

Se `text` não casa com `PURCHASE_RE`, o parser retorna todos os campos vazios (`""`). O webhook **ainda insere** a linha (com col A preenchida pelo `nextInvoiceClosingDate_` e Origem `"Cartão"`), só com os campos extraídos vazios — útil para detectar regex stale na planilha.

## Edge cases

- **Valor negativo:** o regex aceita `-` no grupo 2. Estornos vão como negativos.
- **Estabelecimento com vírgula no nome:** o `(.+?)` é non-greedy, mas casa até a vírgula seguida de `"aprovada"`. Funciona se "aprovada" só aparece no fim.
- **Notificação em outro formato** (banco mudou copy): regex falha → linha em branco. Detectar pela rotina manual ao revisar Lançamentos.
- **Multilinha:** flag `i` (case-insensitive) está, `s` (dotall) não — `.` não casa newline. Notificações empacotadas em uma linha são esperadas.
- **`Compra` aparecer em outro contexto** (ex. notificação de promoção): tipicamente não tem `final \d+` na sequência, então não casa.

## Implementações

- **Backend (autoritativo):** [apps-script/webhook/Webhook.gs:1-2,91-108](../../../apps-script/webhook/Webhook.gs)
- **Helpers:** `parseBrazilNumber_`, `normalizeDate_` em [apps-script/shared/Helpers.gs](../../../apps-script/shared/Helpers.gs).
- **PWA / Flutter:** N/A. Não recebem webhook.

## Specs relacionadas

- [../api/webhook.md](../api/webhook.md)
- [../rules/invoice-closing-date.md](invoice-closing-date.md)
- [../rules/card-to-person.md](card-to-person.md)
