---
status: stable
last_updated: 2026-05-11
---

# Lançamento — lista das últimas entradas + edit modal + novo

Página com as 10 últimas linhas inseridas na planilha, em ordem de inserção (mais recente primeiro). Cada item abre um modal de edição. No Flutter (Bloom), uma segunda aba `+ Novo` permite criar lançamentos manualmente via `addEntry`.

> **Flutter (Bloom)**: 2 tabs (`Lançamentos` + `+ Novo`). PWA legada tem só a lista (sem tab Novo).

## Contexto

Foco em corrigir lançamentos automáticos — o webhook insere com classificação inferida; o usuário muitas vezes precisa ajustar `categoria`, `rateio`, ou marcar parcela. Sem essa página, o usuário teria que abrir a planilha no Sheets — atrito alto.

## Regras

### Inputs / data

- `useLastEntries(10)` → últimos 10 entries com `row` (sheet row 1-indexed).
- `useMonthData(currentMonth)` → para sugerir `categoria` no autocomplete do modal. Usa `currentMonth` do StickyHeader em modo "disabled" (sempre fatura mais recente — não a selecionada pelo usuário).

### StickyHeader em modo disabled

A página de Lançamento monta uma instância **própria** do StickyHeader com `disabled={true}`. Ele:
- Faz `useMonthData(null)` (sempre o mais recente, ignorando `currentMonth` do store).
- Mostra o mês fixo (não permite trocar).
- Mantém os 3 tiles (Total geral, Total cartão, Total parcelado) calculados sobre essa fatura.

Razão: editar um lançamento só faz sentido se você está vendo a fatura corrente (lançamentos novos vão sempre nela). Permitir mudar o filtro de mês confundiria.

### Tabs (Flutter, Bloom)

Apenas no Flutter:
- **`Lançamentos`** (default) — listagem (descrita abaixo).
- **`+ Novo`** — form funcional para criar entradas manualmente via `addEntry`. Hero gradient com `TextField` editável (valor R$). Abaixo:
  - **Estabelecimento** (TextField, obrigatório).
  - **Categoria** (Autocomplete; sugestões = `monthData.rows[*].categoria` deduped+sort).
  - **Forma** (segmented `Cartão`/`Pix` → mapeia `Pix` → `"Pix (contas)"` no envio).
  - **Divisão** (segmented `Metade`/`Júlio`/`Dani`/`Alzira` → envia como `rateio`).
  - **Parcela** (stepper 1..99 — só renderiza se Forma=`Cartão`). Default 1 (à vista).
  - **Cartão (4 dígitos)** (TextField, só se Forma=`Cartão`).
  - **Marcar para Acerto Final** (Switch, só se Forma=`Pix`; envia `acerto: "Sim"`).
  - **Salvar lançamento** → `api.addEntry(...)`. Loading state desabilita botão. Erro (server ou validação local) aparece em pílula vermelha.
- **Defaults enviados ao backend**: `data` e `dataRef` omitidos → o Apps Script usa hoje/agora no TZ. `categoria` vazia OK. `cardLast4` vazio OK. `parcela` enviado como `"1/N"` quando N>1, senão `""`.
- **On success**: SnackBar verde "Lançamento criado.", `ref.invalidate(lastEntriesProvider)` + `ref.invalidate(monthDataProvider)`, e `widget.onCancel()` volta pra aba `Lançamentos`.

### Lista de entries

Cada entry renderiza como um botão (`<button>`):

```
[dataRef] · [origem]
[descricao]                    R$ [valor]
[categoria pill] [rateio pill] [parcela pill se total > 1]
```

- Pills `categoria` e `rateio`: cor base (`bg-[#f0ece2]`). Só aparecem se não-vazias.
- Pill de parcela: cor de destaque (`bg-accent text-accent-fg`). Aparece só se `parcelaTotal(parcela) > 1`. Mostra `e.parcela` verbatim (ex.: `"1/3"`).

Click → abre modal com essa entry.

### Modal de edição

Componente `EditModal`:

- **Read-only fields:** `Data de referência` (`dataRef`), `Origem`.
- **Editáveis:**
  - Descrição (text)
  - Valor (R$, number step 0.01, inputmode decimal)
  - Categoria (text + datalist com opções extraídas de `monthData.rows[*].categoria`, dedupe + sort)
  - Rateio (select: `""`, `"Julio"`, `"Dani"`, `"Metade"`, `"Alzira"`)
  - Parcela (stepper 1..99 — ver [parcela-format.md](../rules/parcela-format.md))

#### Parcela math no modal

Ao abrir:
- `originalTotal = entry.valor * parcelaTotal(entry.parcela)`.

Stepper `±`:
- Clamp `parcela` em `[1, 99]`.
- `valor = originalTotal / parcela`.

Edição manual de valor:
- `originalTotal = valor * parcela`.

Display: `{parcela}x` no centro do stepper. Abaixo: `Total da compra: R$ {formatMoney(originalTotal)}` (atualiza em tempo real).

### Save

- Body: `{ row: entry.row, fields: { descricao: trim, valor, categoria: trim, rateio, parcela: parcela > 1 ? "1/${parcela}" : "" } }`.
- Mutation: `useUpdateEntry`. `onSuccess` invalida `["lastEntries"]` e `["monthData"]`.
- Após sucesso: `onClose()` → fecha modal.

### Delete

- Confirma com `window.confirm("Excluir este lançamento? Esta ação não pode ser desfeita.")`.
- Se confirmado: `useDeleteEntry`. Invalida as mesmas queries.
- Após sucesso: `onClose()`.

### Erros

- HTTP/server error: exibe `"Erro: <mensagem>"` em vermelho dentro do modal. Não fecha.
- Botões ficam disabled durante mutation pending.

## Edge cases

- **Sem lançamentos**: lista mostra `"Sem lançamentos."` após loading.
- **`monthData` ainda carregando** quando o modal abre: datalist de categoria vazio. OK — usuário pode digitar livre.
- **Concorrência**: usuário edita uma linha, webhook insere outra ao mesmo tempo. As mutations invalidam cache; a próxima leitura pega tudo. Sem optimistic update.
- **Parcela = 1 quando entry tinha `"3"` (legado):** save converte para `""`. Esperado.
- **Stepper em 1:** botão `−` ainda funciona mas clamp em 1.

## Implementações

- **PWA:** [web/src/pages/LancamentoPage.tsx](../../../web/src/pages/LancamentoPage.tsx) + [web/src/components/EditModal.tsx](../../../web/src/components/EditModal.tsx).
- **Hooks:** [useLastEntries.ts](../../../web/src/hooks/useLastEntries.ts) — `useLastEntries`, `useUpdateEntry`, `useDeleteEntry`.
- **Após Onda 2:** parcela math em `EditModal` move helpers para `core/rules/parcela.ts`. JSX permanece.
- **Flutter:** [app/lib/features/lancamento/lancamento_page.dart](../../../app/lib/features/lancamento/lancamento_page.dart) com 2 tabs (`Lançamentos` + `+ Novo` stub); `Dialog` para edit modal; mesma math.

## Specs relacionadas

- [../rules/parcela-format.md](../rules/parcela-format.md)
- [../api/endpoints.md](../api/endpoints.md) — `lastEntries`, `updateEntry`, `deleteEntry`
- [../state/persistence.md](../state/persistence.md)
