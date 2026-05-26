# Plano: Nova fatura (gatilho manual)

## Context

Hoje o bloco "início de fatura" (linha azul + despesas fixas) só é criado quando uma compra de Cartão chega via webhook. Se nenhuma compra acontece (ou notificação não veio), o usuário fica sem fatura nova — sem despesas fixas, sem rollover de parcelas.

Solução: opção manual "Nova fatura" no menu da aba Início que:
1. Insere o bloco de fatura (mesmo layout do webhook) com `data = dia 6 do próximo mês`.
2. Rola parcelas pendentes (`X/Y` onde `X < Y`) da fatura mais recente para a nova com `(X+1)/Y`, preservando `data referência` original (audit trail).

UI: os 3 botões existentes (refresh / configurações / sair) viram um menu hambúrguer único + nova entrada "Nova fatura". Só na aba Início (mantém estrutura atual — sem refactor do AppShell). Mesma mudança serve APK e PWA porque é o mesmo codebase Flutter.

## Decisões já tomadas

- Hambúrguer só na aba Início.
- Confirmação antes de inserir (modal "Criar fatura DD/MM/YYYY? Vai inserir despesas fixas e parcelas pendentes").
- Se fatura já existe na planilha → erro "fatura DD/MM já existe".
- Parcela rolada mantém coluna B original.
- Layout do bloco: parcelas **acima** das despesas fixas (entradas dinâmicas têm prioridade visual; despesas fixas são previsíveis).
- Parcela malformada em rollover: pula silenciosamente (regex tolerante, não fail-hard como `loadFixedExpenses_`).

## Backend — Apps Script

### apps-script/shared/Helpers.gs (modificar)

Adicionar 2 helpers:

- **`findCurrentInvoice_(sheet, newClosing)`** — varre colunas A+I, retorna `{ closing: "DD/MM/YYYY", rows: [{ rowIndex, values }] }` da fatura mais recente STRICTLY LESS THAN `newClosing`. Retorna `null` se sheet só tem header ou se não há fatura anterior. Compara datas via `parseBrDate_` (já existe no arquivo).
- **`rolloverParcelaRow_(rowValues, newClosing)`** — recebe array 10-col, retorna novo array 10-col ou `null`. Match em col I via `/^\s*(\d+)\s*\/\s*(\d+)\s*$/`. Pula quando: não bate regex, ou `X >= Y`, ou col I vazia. Quando rola: muda col A para `newClosing`, col I para `${X+1}/${Y}`. Resto preservado.

### apps-script/webhook/FixedExpenses.gs (modificar)

- Extrair helper privado **`buildInvoiceBlock_(invoiceClosing, parcelaRows)`** que monta `[blank, ...parcelaRows, ...fixedRows, blank, blank_blue, blank]` (parcelas acima das fixas) usando `loadFixedExpenses_()` internamente. Retorna `{ block, blueRowOffset }`. Garante que webhook e Nova fatura produzem layout idêntico.
- Refatorar `appendMonthlyFixedIfNeeded_` para chamar `buildInvoiceBlock_(invoiceClosing, [])`. Comportamento atual do webhook preservado bit-a-bit.
- Adicionar **`newInvoice_(token)`** — endpoint handler.

### apps-script/dashboard/Dashboard.gs (modificar)

Adicionar `case "newInvoice": return jsonResponse_(newInvoice_(body.token));` no switch do `doPost`.

## Frontend — Flutter

### app/lib/core/rules/invoice_closing.dart (novo)

Porta Dart de `nextInvoiceClosingDate_()`. Pure function, sem deps externas. `kInvoiceClosingDay = 6`.

### app/lib/core/types.dart (modificar)

Adicionar `NewInvoiceResponse` class + `fromJson`.

### app/lib/api/endpoints.dart (modificar)

Adicionar método `Future<NewInvoiceResponse> newInvoice()`.

### app/lib/features/inicio/inicio_page.dart (modificar)

- Substituir `_TopAppBar` por `_BloomMenu` (inline). Único `_IconBtn` com `Icons.menu`.
- Tap: `showMenu` (não `PopupMenuButton`) com itens: Nova fatura | Atualizar | Divider | Configurações | Sair.
- Handler `onNovaFatura`: dialog confirma → POST → invalida providers → SnackBar.

## Spec docs

- **`docs/specs/rules/new-invoice.md`** (novo) — regra completa.
- **`docs/specs/api/endpoints.md`** (modificar) — adicionar entrada `newInvoice`.
- **`docs/specs/pages/inicio.md`** (modificar) — descrever menu hambúrguer.
- **`docs/specs/rules/fixed-expenses.md`** (modificar) — link para new-invoice.
- **`docs/specs/rules/parcela-format.md`** (modificar) — link para new-invoice.

## Tradeoffs

- `buildInvoiceBlock_` compartilhado entre webhook e Nova fatura (layout único).
- `nextClosing` computado no Dart (sem round-trip).
- `showMenu` em vez de `PopupMenuButton` (estilo Bloom).
- Skip silencioso de parcela malformada (vs. fail-hard das fixas).
- Sem LockService a princípio (1 usuário, 1 fatura/mês).

## Edge cases

- Sheet só com headers: parcelaRows = [], só fixas no bloco.
- Fatura atual sem parcelas: parcelaRows = [], só fixas.
- Aba `despesas-fixas` malformada: `loadFixedExpenses_` lança → `newInvoice_` retorna `fixed_expenses_failed`.
- Parcela `5/5`: skip (X >= Y).
- Parcela `"1/3 (estorno)"`: skip (regex falha).

## Verification

1. **Backend dry-run** via editor GAS pós-push.
2. **Backend real** rodar `newInvoice_(<token>)` uma vez; conferir planilha.
3. **Dedup** rodar 2x; segunda retorna `invoice_already_exists`.
4. **Frontend** `cd app && flutter run -d chrome`; testar dialog + SnackBar.
5. **Regressão webhook** disparar webhook real; conferir layout do bloco igual ao antes.
6. **Build APK** `flutter build apk --release`.
