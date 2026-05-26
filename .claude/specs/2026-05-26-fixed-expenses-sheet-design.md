---
status: draft
date: 2026-05-26
related-specs:
  - docs/specs/rules/fixed-expenses.md
  - docs/specs/data/despesas-sheet.md
---

# Migrar `FIXED_EXPENSES` para aba `despesas-fixas`

## Objetivo

Tirar o array hard-coded `FIXED_EXPENSES` do código do Apps Script e colocar a lista numa nova aba `despesas-fixas` da mesma planilha. Permite editar despesas fixas sem deploy de código.

## Contexto

Hoje as 15 despesas fixas vivem como constante em [apps-script/webhook/FixedExpenses.gs:4-20](../../apps-script/webhook/FixedExpenses.gs). Qualquer mudança (novo valor de plano de saúde, novo item, remoção) exige editar o código + push via clasp. A aba `despesas-fixas` já foi criada manualmente na planilha (vazia, só com a estrutura da aba).

## Decisões (de brainstorming)

1. **Schema**: 7 colunas espelhando os campos do array atual.
2. **Tratamento de erro**: falhar duro — aba ausente, vazia, ou linha malformada → webhook retorna 500 com mensagem apontando a linha.
3. **Seed**: função one-shot `seedFixedExpenses_()` que o usuário roda uma vez no editor GAS para popular as 15 linhas atuais.

## Schema da aba `despesas-fixas`

| # | Letra | Header     | Tipo        | Validação                                     |
|---|-------|------------|-------------|-----------------------------------------------|
| 1 | A     | `Dia`      | number int  | 1–31                                          |
| 2 | B     | `Descrição`| string      | não-vazia                                     |
| 3 | C     | `Valor`    | number      | qualquer (negativos OK, ex.: ajuda de custo)  |
| 4 | D     | `Origem`   | string      | não-vazia                                     |
| 5 | E     | `Categoria`| string      | não-vazia                                     |
| 6 | F     | `Rateio`   | string enum | `Julio` \| `Dani` \| `Metade` \| `Alzira`     |
| 7 | G     | `Acerto`   | string      | `""` \| `"Sim"`                                |

Linha 1 = headers (bold), linha 2+ = dados. Ordem da aba determina ordem visual do bloco inserido em `Despesas`.

## Componentes

### `apps-script/shared/Constants.gs`

Adicionar:

```js
const FIXED_SHEET_NAME = "despesas-fixas";
```

### `apps-script/webhook/FixedExpenses.gs`

Remover constante `FIXED_EXPENSES`. Adicionar duas funções:

**`loadFixedExpenses_()`** — lê e valida a aba, retorna array no shape antigo.

```js
function loadFixedExpenses_() {
  const ss = SpreadsheetApp.openById(SHEET_ID);
  const sheet = ss.getSheetByName(FIXED_SHEET_NAME);
  if (!sheet) throw new Error(`aba "${FIXED_SHEET_NAME}" não existe`);

  const last = sheet.getLastRow();
  if (last < 2) throw new Error(`aba "${FIXED_SHEET_NAME}" está vazia`);

  const rows = sheet.getRange(2, 1, last - 1, 7).getValues();
  return rows.map((r, i) => {
    const line = i + 2;
    const [dia, descricao, valor, origem, categoria, rateio, acerto] = r;

    if (!Number.isInteger(dia) || dia < 1 || dia > 31)
      throw new Error(`despesas-fixas L${line}: dia inválido (${dia})`);
    if (!descricao || typeof descricao !== "string")
      throw new Error(`despesas-fixas L${line}: descrição vazia`);
    if (typeof valor !== "number" || isNaN(valor))
      throw new Error(`despesas-fixas L${line}: valor inválido (${valor})`);
    if (!origem) throw new Error(`despesas-fixas L${line}: origem vazia`);
    if (!categoria) throw new Error(`despesas-fixas L${line}: categoria vazia`);
    if (!["Julio", "Dani", "Metade", "Alzira"].includes(String(rateio)))
      throw new Error(`despesas-fixas L${line}: rateio inválido (${rateio})`);
    const acertoStr = String(acerto || "");
    if (acertoStr !== "" && acertoStr !== "Sim")
      throw new Error(`despesas-fixas L${line}: acerto inválido (${acertoStr})`);

    return {
      refDay: dia,
      description: descricao,
      value: valor,
      origem,
      categoria,
      rateio: String(rateio),
      acerto: acertoStr || undefined,
    };
  });
}
```

**`appendMonthlyFixedIfNeeded_(sheet, invoiceClosing)`** — mesma lógica de antes, só troca a fonte do array:

```js
function appendMonthlyFixedIfNeeded_(sheet, invoiceClosing) {
  const lastRow = sheet.getLastRow();
  if (lastRow > 1) {
    const rows = sheet.getRange(2, 1, lastRow - 1, 5).getValues();
    const exists = rows.some(
      (r) =>
        formatBrDate_(r[0]) === invoiceClosing && String(r[4]).trim() === ORIGEM,
    );
    if (exists) return;
  }
  const fixed = loadFixedExpenses_();   // ← única mudança
  const [, mm, yyyy] = invoiceClosing.split("/");
  const fixedRows = fixed.map((e) => {
    const dd = ("0" + e.refDay).slice(-2);
    return [
      invoiceClosing,
      dd + "/" + mm + "/" + yyyy,
      e.description,
      e.value,
      e.origem,
      e.categoria,
      e.rateio,
      "",
      "",
      e.acerto || "",
    ];
  });
  const blank = ["", "", "", "", "", "", "", "", "", ""];
  const block = [blank].concat(fixedRows).concat([blank, blank, blank]);
  sheet.insertRowsBefore(2, block.length);
  sheet.getRange(2, 1, block.length, 10).setValues(block);
  sheet.getRange(block.length, 1, 1, 10).setBackground("#cfe2f3");
}
```

**`seedFixedExpenses_()`** — função utilitária one-shot. Idempotente via guard: se a aba já tem dados (linha 2+), aborta.

```js
function seedFixedExpenses_() {
  const ss = SpreadsheetApp.openById(SHEET_ID);
  const sheet = ss.getSheetByName(FIXED_SHEET_NAME);
  if (!sheet) throw new Error(`crie a aba "${FIXED_SHEET_NAME}" primeiro`);
  if (sheet.getLastRow() > 1)
    throw new Error("aba já tem dados — abortando para não duplicar");

  const headers = ["Dia", "Descrição", "Valor", "Origem", "Categoria", "Rateio", "Acerto"];
  const data = [
    [6,  "Diarista",                                                       1500,    "Pix (contas)", "Contas", "Dani",  ""   ],
    [6,  "Plano de Saúde (Dani)",                                          761.81,  "Pix (contas)", "Contas", "Dani",  ""   ],
    [6,  "Plano de Saúde (Julio)",                                         761.81,  "Pix (contas)", "Contas", "Julio", "Sim"],
    [7,  "Mensalidade creche 1/2",                                         1741.40, "Pix (contas)", "Contas", "Dani",  "Sim"],
    [7,  "Mensalidade creche 2/2",                                         1741.40, "Pix (contas)", "Contas", "Julio", "Sim"],
    [5,  "Ajuda de custo (Creche)",                                        -620,    "Pix (contas)", "Contas", "Dani",  ""   ],
    [6,  "Claro Internet - https://minhaclaroresidencial.claro.com.br",    0.01,    "Pix (contas)", "Contas", "Dani",  ""   ],
    [5,  "Gás",                                                            120.42,  "Pix (contas)", "Contas", "Dani",  "Sim"],
    [10, "Condomínio 1/2",                                                 1550,    "Pix (contas)", "Contas", "Julio", "Sim"],
    [10, "Condomínio 1/2",                                                 0,       "Pix (contas)", "Contas", "Dani",  ""   ],
    [7,  "Energia (débito automático)",                                    500,     "Pix (contas)", "Contas", "Dani",  ""   ],
    [15, "Guia de Previdência Social",                                     1300,    "Pix (contas)", "Contas", "Julio", ""   ],
    [15, "Guia de Previdência Social (coloquei pra Dani pra equilibrar)",  1300,    "Pix (contas)", "Contas", "Dani",  ""   ],
    [5,  "Dízimo",                                                         500,     "Pix (contas)", "Contas", "Julio", ""   ],
    [5,  "Dízimo",                                                         500,     "Pix (contas)", "Contas", "Dani",  ""   ],
  ];

  sheet.getRange(1, 1, 1, headers.length).setValues([headers]).setFontWeight("bold");
  sheet.getRange(2, 1, data.length, headers.length).setValues(data);
}
```

## Data flow

```
Webhook recebe push de cartão
  → handleWebhookBody_
    → appendMonthlyFixedIfNeeded_(sheet, invoiceClosing)
      → dedup check (já existe linha desta fatura+Cartão?)
      → loadFixedExpenses_()           ← lê aba despesas-fixas + valida
      → constrói block (idêntico ao atual)
      → insertRowsBefore(2, ...) + setValues + linha azul
```

## Error handling

Toda violação de validação no `loadFixedExpenses_()` lança `Error` com prefixo `despesas-fixas L{linha}:`. Webhook propaga via 500. Usuário vê a falha imediata no shortcut do iPhone e corrige a célula na planilha.

Casos cobertos:
- Aba ausente → `aba "despesas-fixas" não existe`
- Aba só com headers → `aba "despesas-fixas" está vazia`
- `dia` não-int ou fora de 1..31
- `descricao` vazia
- `valor` não-numérico
- `origem` vazia
- `categoria` vazia
- `rateio` fora do enum `{Julio, Dani, Metade, Alzira}`
- `acerto` fora de `{"", "Sim"}`

## Specs do produto a atualizar

### `docs/specs/rules/fixed-expenses.md`

- Substituir seção "Bloco inserido" → referenciar `loadFixedExpenses_()` em vez de constante.
- Remover tabela "Lista atual de despesas fixas" — vira referência para a aba.
- Atualizar seção "Implementações": apontar para a aba `despesas-fixas` + o loader.
- Edge case novo: "aba malformada → webhook 500".

### `docs/specs/data/despesas-fixas-sheet.md` (novo)

Mesmo template do `despesas-sheet.md`: schema (7 colunas), regras, edge cases, implementações.

## Rollout

1. Aplicar diffs em código (Constants + FixedExpenses).
2. `clasp push -f` para subir o código (Head Deployment fica ativo imediatamente).
3. **Logo em seguida**: abrir editor GAS, rodar `seedFixedExpenses_()` uma vez.
4. Conferir visualmente: aba `despesas-fixas` tem header + 15 linhas.
5. Atualizar specs em `docs/specs/`.
6. Validação end-to-end na próxima primeira-compra-de-fatura (ou compra de teste manual).

**Janela de risco**: entre os passos 2 e 3, se uma compra de cartão chegar e for a primeira da fatura, o webhook 500a (aba vazia). Janela curta (segundos). Para zerar risco: rodar a sequência fora de horário comercial, ou aceitar como risco transiente. O webhook do iPhone retorna erro visível, então é fácil de detectar e reenviar manualmente.

## Não-objetivos

- **Cache.** `appendMonthlyFixedIfNeeded_` roda no máximo 1x/mês (primeira compra de cada fatura). Custo de I/O é desprezível.
- **UI Flutter pra editar a aba.** O app não escreve a aba — é write-once via planilha do Google.
- **Migrar a tabela markdown da spec pra ser auto-gerada da aba.** Manter desacoplado; a tabela some da spec.
- **Testes automatizados.** Projeto não tem framework de teste no Apps Script.
