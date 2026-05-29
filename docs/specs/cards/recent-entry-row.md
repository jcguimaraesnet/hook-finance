---
status: stable
last_updated: 2026-05-29
---

# RecentEntryRow — linha de lançamento no app

Widget compartilhado usado em todas as listas de lançamentos do Flutter app: [Início](../pages/inicio.md) (últimos 2), [Lançamento](../pages/lancamento.md) (até 100) e [Detalhe](../pages/detalhe.md) (pessoais do mês).

## Contexto

Antes de 2026-05-29, o avatar mostrava a 1ª letra da `descricao` e usava cores arbitrárias por rateio (Júlio=amber, sem relação com a identidade visual da pessoa). Isso entregava zero informação útil — a 1ª letra do estabelecimento já estava no texto ao lado, e a cor do quadradinho não ajudava a escanear a lista por rateio.

A regra atual: o avatar passa a representar o **rateio** da linha — quem paga, num símbolo + cor consistente com o resto do app.

## Anatomia

```
┌──────────────────────────────────────────────────────────────┐
│ ┌────┐                                                       │
│ │ ½  │  Mercado Extra                              R$ 89,90  │
│ └────┘  29/05/2026 18:42 · Alimentação · dividido · (1 / 3)  │
└──────────────────────────────────────────────────────────────┘
```

## Regras

### Avatar — símbolo

| Rateio | Símbolo |
|---|---|
| `Metade` | `½` |
| `Dani` | `D` |
| `Julio` | `J` |
| `Alzira` | `A` |
| Outro não-vazio | 1ª letra do rateio (uppercase) |
| Vazio | `?` |

### Avatar — cor (fundo e texto)

A cor `tone` é aplicada como `tone.withValues(alpha: 0.13)` no fundo e como cor sólida no texto.

| Rateio | `tone` |
|---|---|
| `Metade` | `BloomColors.muted` |
| `Dani` | `BloomColors.violet` (= `forPerson(dani)`) |
| `Julio` | `BloomColors.mint` (= `forPerson(julio)`) |
| Outro não-vazio (ex.: `Alzira`) | `BloomColors.amber` |
| Vazio | `BloomColors.muted` |

Cores de `Dani`/`Julio` derivam de `BloomColors.forPerson()` — invertidas em 2026-05-29 (ver [../pages/inicio.md](../pages/inicio.md)).

### Linha de metadados (2ª linha)

Formato: `dateRef · cat · split [· (X / Y)]`

- `dateRef` = `entry.dataRef` se não-vazia, senão `entry.data`.
- `cat` = `entry.categoria` se não-vazia, senão `—`.
- `split` = `"dividido"` se `rateio = Metade`, `—` se vazio, senão o próprio `rateio`.
- `(X / Y)` aparece **apenas** quando `entry.parcela` está preenchida e parseia como `X/Y`. Espaços ao redor de `/` são obrigatórios no display (`"(1 / 3)"`, não `"(1/3)"`). Quando `parcela` é legado sem `/` (ex.: `"3"`), o sufixo não aparece.

Tipo: `BloomTypography.mono`, `fontSize: 10`, `color: BloomColors.muted`.

### highlightMissing (override)

Quando o widget é instanciado com `highlightMissing: true` E `entry.categoria` ou `entry.rateio` está vazio:

- `tone` vira `BloomColors.bad` (sobrepõe a tabela acima).
- Cor da descrição vira `BloomColors.bad` (em vez de `BloomColors.ink`).

Usado na lista de Lançamentos para destacar entries do webhook que ainda não foram classificadas. Início e Detalhe não usam essa flag.

## Edge cases

- `descricao` vazia → texto principal mostra `—`.
- `rateio` vazio + `highlightMissing: false` → avatar `?` em tom `muted`.
- `parcela = "1/1"` → ainda mostra `(1 / 1)` na linha? **Não:** spec emite só quando o formato parseia E `Y > 0`. `"1/1"` parseia e tem `Y=1` — emite `(1 / 1)`. Isso é intencional (raro na prática) e consistente com a regra "se tem dado, mostra".
- `onTap == null` (Início, Detalhe) → widget não envolve em `InkWell`, não mostra `chevron_right`.

## Implementações

- **Flutter:** [app/lib/widgets/bloom/recent_entry_row.dart](../../../app/lib/widgets/bloom/recent_entry_row.dart).
- **PWA:** sem equivalente — a PWA React congelada usa pills em vez de avatar (ver [../pages/lancamento.md](../pages/lancamento.md), seção "Lista de entries (PWA legada)").

## Specs relacionadas

- [../pages/inicio.md](../pages/inicio.md) — cores por pessoa.
- [../pages/lancamento.md](../pages/lancamento.md) — uso na lista editável.
- [../pages/detalhe.md](../pages/detalhe.md) — uso na lista de despesas pessoais.
- [../rules/parcela-format.md](../rules/parcela-format.md) — formato `X/Y`.
