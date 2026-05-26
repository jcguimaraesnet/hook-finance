# Fixed Expenses — Sheet-backed Configuration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Migrar a lista `FIXED_EXPENSES` (hard-coded em `apps-script/webhook/FixedExpenses.gs`) para uma aba `despesas-fixas` na planilha do Google Sheets, com validação dura no loader e função one-shot de seed.

**Architecture:** Backend Apps Script lê a aba `despesas-fixas` no início de `appendMonthlyFixedIfNeeded_()`. Validação por linha lança erro com prefixo `despesas-fixas L{N}:` para webhook propagar como 500. Função `seedFixedExpenses_()` popula a aba uma única vez. Specs em `docs/specs/` documentam o novo schema.

**Tech Stack:** Google Apps Script (V8), Google Sheets API, clasp (push), markdown specs.

**Spec:** [.claude/specs/2026-05-26-fixed-expenses-sheet-design.md](../specs/2026-05-26-fixed-expenses-sheet-design.md)

---

## File Structure

- **Modify** [apps-script/shared/Constants.gs](../../apps-script/shared/Constants.gs) — adiciona constante `FIXED_SHEET_NAME`.
- **Rewrite** [apps-script/webhook/FixedExpenses.gs](../../apps-script/webhook/FixedExpenses.gs) — remove constante `FIXED_EXPENSES`, adiciona `loadFixedExpenses_()`, atualiza `appendMonthlyFixedIfNeeded_()`, adiciona `seedFixedExpenses_()`.
- **Modify** [docs/specs/rules/fixed-expenses.md](../../docs/specs/rules/fixed-expenses.md) — atualiza seção "Bloco inserido", "Implementações", "Edge cases"; remove tabela "Lista atual".
- **Create** `docs/specs/data/despesas-fixas-sheet.md` — schema da nova aba (espelha estilo de `despesas-sheet.md`).

Sem testes automatizados (projeto não tem framework de teste pra Apps Script). Validação é manual via push + execução da função de seed no editor GAS.

---

## Task 1: Adicionar constante `FIXED_SHEET_NAME`

**Files:**
- Modify: `apps-script/shared/Constants.gs`

- [ ] **Step 1: Adicionar a constante ao final do arquivo**

Editar `apps-script/shared/Constants.gs`, adicionar nas últimas linhas (depois do bloco `CARDS`):

```js
const FIXED_SHEET_NAME = "despesas-fixas";
```

Arquivo final esperado:

```js
const SHEET_ID = "1IbxnOnBuhLIj5i8nqepk-Bva1IhmKalyuLXIyN56V8k";
const SHEET_NAME = "Despesas";
const FIXED_SHEET_NAME = "despesas-fixas";

const INVOICE_CLOSING_DAY = 6;
const ORIGEM = "Cartão";

// Map dos 4 finais de cartão para o titular.
// Chave = últimos 4 dígitos. Valor = nome (Julio | Dani).
const CARDS = {
  "1018": "Julio",
  "9727": "Julio",
  "4750": "Dani",
  "0784": "Dani",
};
```

- [ ] **Step 2: Verificar leitura**

Ler `apps-script/shared/Constants.gs` e confirmar que `FIXED_SHEET_NAME = "despesas-fixas"` está presente.

---

## Task 2: Reescrever `FixedExpenses.gs`

**Files:**
- Rewrite: `apps-script/webhook/FixedExpenses.gs`

Este arquivo passa por três mudanças cumulativas: remoção do array, adição de `loadFixedExpenses_()`, adição de `seedFixedExpenses_()`, e atualização de `appendMonthlyFixedIfNeeded_()`. Vou fazer tudo num único Write porque o arquivo é pequeno.

- [ ] **Step 1: Substituir o conteúdo inteiro do arquivo**

Conteúdo final de `apps-script/webhook/FixedExpenses.gs`:

```js
// Despesas fixas são lidas da aba `despesas-fixas` no momento da inserção.
// Spec: docs/specs/rules/fixed-expenses.md
// Schema da aba: docs/specs/data/despesas-fixas-sheet.md

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
      origem: origem,
      categoria: categoria,
      rateio: String(rateio),
      acerto: acertoStr || undefined,
    };
  });
}

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
  const fixed = loadFixedExpenses_();
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
      "", // Final do cartão (n/a para Pix)
      "", // Parcela (despesas fixas nunca são parceladas)
      e.acerto || "",
    ];
  });
  const blank = ["", "", "", "", "", "", "", "", "", ""];
  // Visual top-down dentro do bloco inserido:
  // [blank, ...fixed, blank, blue blank, blank]
  const block = [blank].concat(fixedRows).concat([blank, blank, blank]);
  sheet.insertRowsBefore(2, block.length);
  sheet.getRange(2, 1, block.length, 10).setValues(block);
  // Linha azul = penúltima do bloco. Inserido a partir da linha 2,
  // então fica na linha (2 + block.length - 2) = block.length.
  sheet.getRange(block.length, 1, 1, 10).setBackground("#cfe2f3");
}

// One-shot — rodar manualmente no editor do Apps Script para popular a aba
// `despesas-fixas` com a lista atual. Idempotente: aborta se a aba já tem dados.
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

- [ ] **Step 2: Verificar leitura**

Ler `apps-script/webhook/FixedExpenses.gs` e confirmar:
- Não existe mais constante `FIXED_EXPENSES` no topo.
- Existem três funções: `loadFixedExpenses_`, `appendMonthlyFixedIfNeeded_`, `seedFixedExpenses_`.
- `appendMonthlyFixedIfNeeded_` chama `loadFixedExpenses_()` antes de construir `fixedRows`.

---

## Task 3: Atualizar `docs/specs/rules/fixed-expenses.md`

**Files:**
- Modify: `docs/specs/rules/fixed-expenses.md`

- [ ] **Step 1: Substituir seção "Bloco inserido"**

Localizar a seção que começa com `### Bloco inserido` (linha ~24) e substituir do `### Bloco inserido` até antes de `### Layout no sheet`.

Old (a substituir):

```markdown
### Bloco inserido

Composto pelo array `FIXED_EXPENSES` em [FixedExpenses.gs](../../../apps-script/webhook/FixedExpenses.gs). Cada item:

```js
{
  refDay: <1-31>,
  description: <string>,
  value: <number>,
  origem: "Pix (contas)",
  categoria: "Contas",
  rateio: "Julio" | "Dani",
  acerto?: "Sim",  // se omitido = ""
}
```

Para cada item, o backend constrói uma row:
```

New:

```markdown
### Bloco inserido

Composto pelo retorno de `loadFixedExpenses_()` em [FixedExpenses.gs](../../../apps-script/webhook/FixedExpenses.gs), que lê e valida a aba [despesas-fixas](../data/despesas-fixas-sheet.md). Cada item retornado:

```js
{
  refDay: <1-31>,
  description: <string>,
  value: <number>,
  origem: <string>,
  categoria: <string>,
  rateio: "Julio" | "Dani" | "Metade" | "Alzira",
  acerto?: "Sim",  // undefined se a célula estiver vazia
}
```

Para cada item, o backend constrói uma row:
```

- [ ] **Step 2: Remover seção "Lista atual de despesas fixas"**

Localizar a seção que começa com `### Lista atual de despesas fixas` (linha ~71) e remover **toda a seção** incluindo a tabela e o parágrafo final. Substituir por:

Old (a remover/substituir):

```markdown
### Lista atual de despesas fixas

| description | refDay | value | rateio | acerto |
|---|---|---|---|---|
| Diarista | 6 | 1500 | Dani | |
| Plano de Saúde (Dani) | 6 | 761,81 | Dani | |
| Plano de Saúde (Julio) | 6 | 761,81 | Julio | Sim |
| Mensalidade creche 1/2 | 7 | 1741,40 | Dani | Sim |
| Mensalidade creche 2/2 | 7 | 1741,40 | Julio | Sim |
| Ajuda de custo (Creche) | 5 | -620 | Dani | |
| Claro Internet | 6 | 0,01 | Dani | |
| Gás | 5 | 120,42 | Dani | Sim |
| Condomínio 1/2 | 10 | 1550 | Julio | Sim |
| Condomínio 1/2 | 10 | 0 | Dani | |
| Energia (débito automático) | 7 | 500 | Dani | |
| Guia de Previdência Social | 15 | 1300 | Julio | |
| Guia de Previdência Social (...) | 15 | 1300 | Dani | |
| Dízimo | 5 | 500 | Julio | |
| Dízimo | 5 | 500 | Dani | |

Mudanças nessa lista refletem na próxima fatura inserida. Não retroativo.
```

New:

```markdown
### Lista atual de despesas fixas

Lista vive na aba `despesas-fixas` da planilha — schema em [../data/despesas-fixas-sheet.md](../data/despesas-fixas-sheet.md). Edição direta no Sheets, sem deploy.

Mudanças refletem na próxima fatura inserida. Não retroativo.
```

- [ ] **Step 3: Atualizar "Edge cases"**

Localizar a seção `## Edge cases` e adicionar este bullet ao final (antes de `## Implementações`):

```markdown
- **Aba `despesas-fixas` ausente, vazia, ou com linha malformada:** `loadFixedExpenses_()` lança erro `despesas-fixas L{N}: ...`. Webhook propaga como 500. A primeira compra de fatura nova não é registrada até a aba ser corrigida.
```

- [ ] **Step 4: Atualizar "Implementações"**

Localizar a seção `## Implementações` e substituir:

Old:

```markdown
- **Backend (autoritativo):** [apps-script/webhook/FixedExpenses.gs](../../../apps-script/webhook/FixedExpenses.gs)
- **PWA / Flutter:** N/A (write-only do backend).
```

New:

```markdown
- **Backend (autoritativo):** [apps-script/webhook/FixedExpenses.gs](../../../apps-script/webhook/FixedExpenses.gs) — `loadFixedExpenses_()` (lê/valida aba) e `appendMonthlyFixedIfNeeded_()` (insere bloco). Função one-shot `seedFixedExpenses_()` para popular a aba inicialmente.
- **Configuração:** aba `despesas-fixas` na planilha — schema em [../data/despesas-fixas-sheet.md](../data/despesas-fixas-sheet.md).
- **PWA / Flutter:** N/A (write-only do backend).
```

- [ ] **Step 5: Bump `last_updated`**

Editar o front-matter:

Old:

```markdown
last_updated: 2026-05-07
```

New:

```markdown
last_updated: 2026-05-26
```

- [ ] **Step 6: Verificar leitura**

Ler `docs/specs/rules/fixed-expenses.md` e confirmar:
- `last_updated: 2026-05-26`.
- Seção "Bloco inserido" referencia `loadFixedExpenses_()`.
- Tabela com 15 linhas foi removida.
- Edge case da aba malformada está listado.
- "Implementações" cita aba e seed.

---

## Task 4: Criar `docs/specs/data/despesas-fixas-sheet.md`

**Files:**
- Create: `docs/specs/data/despesas-fixas-sheet.md`

- [ ] **Step 1: Criar o arquivo**

Conteúdo:

````markdown
---
status: stable
last_updated: 2026-05-26
---

# Despesas-fixas — schema da aba

Aba de configuração na mesma planilha. Contém o template das despesas que o backend insere automaticamente no topo de `Despesas` na primeira compra de cartão de cada fatura nova. Spec da regra: [../rules/fixed-expenses.md](../rules/fixed-expenses.md).

## Contexto

Antes era constante hard-coded (`FIXED_EXPENSES` em `apps-script/webhook/FixedExpenses.gs`). Migrado para aba em 2026-05-26 para permitir edição sem deploy. Lida em `loadFixedExpenses_()` toda vez que uma fatura nova começa.

## Regras

### Colunas (7 total)

| # | Letra | Header | Tipo | Validação |
|---|-------|--------|------|-----------|
| 1 | A | `Dia` | number int | 1–31 |
| 2 | B | `Descrição` | string | não-vazia |
| 3 | C | `Valor` | number | qualquer (negativos legítimos para ajustes/estornos) |
| 4 | D | `Origem` | string | não-vazia (atualmente todas `Pix (contas)`) |
| 5 | E | `Categoria` | string | não-vazia (atualmente todas `Contas`) |
| 6 | F | `Rateio` | string enum | `Julio` \| `Dani` \| `Metade` \| `Alzira` |
| 7 | G | `Acerto` | string | `""` \| `"Sim"` |

### Leitura

- Linha 1 = headers. Backend lê de `A2:G{last}`.
- Toda linha é validada — qualquer violação lança erro com prefixo `despesas-fixas L{N}:` e webhook retorna 500.
- A ordem das linhas na aba determina a ordem visual do bloco inserido na aba `Despesas`.

### Escrita

- Edição manual via Google Sheets.
- Função utilitária `seedFixedExpenses_()` em `apps-script/webhook/FixedExpenses.gs` popula a aba inicialmente. Idempotente — aborta se a aba já tem dados.

## Edge cases

- **Aba ausente:** `loadFixedExpenses_()` lança `aba "despesas-fixas" não existe`.
- **Aba só com headers:** lança `aba "despesas-fixas" está vazia`.
- **Linha malformada (qualquer campo):** lança erro identificando o número da linha e o campo. Webhook 500 — primeira compra da fatura não entra até a aba ser corrigida.
- **`Valor = 0`:** legítimo (linha placeholder, ex.: `"Condomínio 1/2"` da Dani). Inserida igual; não polui totais.
- **Linhas em branco no meio:** quebram a leitura (cair em validação de `dia`). Manter sem linhas em branco entre dados.

## Implementações

- **Backend (autoritativo):** [apps-script/webhook/FixedExpenses.gs](../../../apps-script/webhook/FixedExpenses.gs) — `loadFixedExpenses_()` lê e valida; `seedFixedExpenses_()` popula one-shot.
- **Constante do nome da aba:** `FIXED_SHEET_NAME` em [apps-script/shared/Constants.gs](../../../apps-script/shared/Constants.gs).

## Specs relacionadas

- [../rules/fixed-expenses.md](../rules/fixed-expenses.md) — regra de inserção automática.
- [despesas-sheet.md](despesas-sheet.md) — aba destino das linhas geradas.
````

- [ ] **Step 2: Verificar leitura**

Ler `docs/specs/data/despesas-fixas-sheet.md` e confirmar que existe, tem 7 colunas no schema, e referencia `loadFixedExpenses_()`.

---

## Task 5: Commit das mudanças de código + specs

**Files:**
- Commit only

- [ ] **Step 1: Verificar status do git**

Run: `git status`

Expected: 4 arquivos modificados/criados:
- modified: `apps-script/shared/Constants.gs`
- modified: `apps-script/webhook/FixedExpenses.gs`
- modified: `docs/specs/rules/fixed-expenses.md`
- new file: `docs/specs/data/despesas-fixas-sheet.md`

(Os arquivos `.claude/specs/...` e `.claude/plans/...` também aparecem, mas `.claude/` é gitignored — confirmar que não aparecem em status.)

- [ ] **Step 2: Diff de sanity**

Run: `git diff apps-script/`

Expected: ver `FIXED_SHEET_NAME` adicionado em Constants.gs e o refactor completo de FixedExpenses.gs. Nenhuma linha do array antigo `FIXED_EXPENSES` permanece.

- [ ] **Step 3: Commit**

Run:

```powershell
git add apps-script/shared/Constants.gs apps-script/webhook/FixedExpenses.gs docs/specs/rules/fixed-expenses.md docs/specs/data/despesas-fixas-sheet.md
git commit -m "feat(backend): despesas fixas viram aba `despesas-fixas` (config sem deploy)"
```

Expected: commit criado, working tree clean para os arquivos relevantes.

- [ ] **Step 4: Verificar commit**

Run: `git log -1 --stat`

Expected: ver os 4 arquivos no commit.

---

## Task 6: Push para Apps Script via clasp

**Files:**
- Deploy only (sem mudanças locais)

- [ ] **Step 1: Confirmar que clasp está disponível**

Run: `./node_modules/.bin/clasp.cmd --version`

Expected: número de versão do clasp impresso (sem erro).

- [ ] **Step 2: Push do código**

Run: `./node_modules/.bin/clasp.cmd push -f`

Expected: output "Pushed N files" sem erros de sintaxe. Os arquivos listados devem incluir `webhook/FixedExpenses.gs` e `shared/Constants.gs`.

**Atenção:** a partir deste momento, qualquer webhook que dispare uma primeira-compra-de-fatura **vai 500** até o seed rodar (Task 7). Janela de risco curta.

---

## Task 7: Rodar seed no editor do Apps Script (manual)

Este passo é manual — não pode ser automatizado via clasp.

- [ ] **Step 1: Abrir o editor do Apps Script**

No navegador, abrir https://script.google.com e selecionar o projeto `hook-finance` (ou abrir o sheet → Extensões → Apps Script).

- [ ] **Step 2: Confirmar que `webhook/FixedExpenses.gs` mostra o código novo**

No editor, abrir o arquivo `webhook/FixedExpenses.gs` e confirmar que `seedFixedExpenses_` aparece na lista de funções (significa que o push da Task 6 chegou).

- [ ] **Step 3: Selecionar a função `seedFixedExpenses_` e executar**

No dropdown de funções (no topo do editor), escolher `seedFixedExpenses_` → clicar em "Executar" (ou "Run").

Expected: execução conclui sem erros. Logs mostram nenhuma exceção. Se aparecer `aba já tem dados — abortando para não duplicar`, significa que alguém já populou a aba — investigar antes de prosseguir.

- [ ] **Step 4: Verificar visualmente a aba**

Abrir a planilha → aba `despesas-fixas`. Confirmar:
- Linha 1: headers `Dia | Descrição | Valor | Origem | Categoria | Rateio | Acerto` (em negrito).
- Linhas 2–16: 15 itens (Diarista, Plano de Saúde Dani, Plano de Saúde Julio, Mensalidade creche 1/2, Mensalidade creche 2/2, Ajuda de custo, Claro Internet, Gás, Condomínio 1/2 Julio, Condomínio 1/2 Dani, Energia, Guia Julio, Guia Dani, Dízimo Julio, Dízimo Dani).
- Valores numéricos corretos (1500, 761.81, etc.).
- Coluna `Rateio` com `Julio` ou `Dani`; coluna `Acerto` com `Sim` apenas onde apropriado.

---

## Task 8: Validar end-to-end com `loadFixedExpenses_()`

- [ ] **Step 1: Executar `loadFixedExpenses_` manualmente**

No editor do Apps Script, selecionar `loadFixedExpenses_` no dropdown → Executar.

Expected: execução conclui sem erros. Logs vazios (a função não loga, só retorna). Nenhuma exceção de validação.

Se aparecer erro `despesas-fixas L{N}: ...`, alguma célula está fora do schema — corrigir na planilha.

- [ ] **Step 2: (Opcional) Forçar inserção via teste de webhook**

Se quiser validar o fluxo completo agora (sem esperar uma compra real), simular um POST no webhook com payload sintético — mas isso não é parte deste plano de implementação. Marcar como validado quando a próxima compra real de fatura nova chegar e o bloco aparecer corretamente em `Despesas`.

---

## Notes

- **`.claude/` é gitignored** — não vai entrar no commit (confirmar com `git check-ignore .claude/plans/2026-05-26-fixed-expenses-sheet.md`).
- **Sem mudanças no Flutter app** — o app só lê `Despesas` via REST; despesas fixas já chegam lá como linhas comuns.
- **Sem mudanças no webhook proxy (`web/api/`)** — proxy é stateless.
