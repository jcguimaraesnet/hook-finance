# hook-finance

- **PWA (Azure SWA)**: [clique aqui](https://polite-mushroom-0d3d07a0f.7.azurestaticapps.net/)
- **Projeto Apps Script**: [clique aqui](https://script.google.com/home/projects/1HvwjDc_t-XIi1SmZnq5gxrZoTBEw7GlDx98d-UolqRAQBk0BBvGwz9E1/edit)
- **Backend (Apps Script `/exec`)**: [clique aqui](https://script.google.com/macros/s/AKfycby7v9mrOGHV6tIaiOmgs7ZaGolmSTXsEKIj3rYjBlYalePcuBmSM0C35Wc5-vJZRNE-7Q/exec)

Webhook em Google Apps Script que recebe `POST` com notificações de compra no cartão (campos `title` e `text` no body), faz parse do texto, e grava uma nova linha estruturada em uma Google Sheet. Deploy automatizado via GitHub Actions com [`clasp`](https://github.com/google/clasp).

## Estrutura

```
src/
  appsscript.json              # manifest (scopes + webapp config)
  shared/
    Constants.gs               # SHEET_ID, SHEET_NAME, ORIGEM, INVOICE_CLOSING_DAY
    Helpers.gs                 # jsonResponse_, formatBrDate_, parseBrazilNumber_, ...
    Setup.gs                   # setupToken (rodar 1x manualmente)
  webhook/
    Webhook.gs                 # doPost + parser de notificação
    FixedExpenses.gs           # despesas fixas inseridas no início da fatura
  dashboard/
    Dashboard.gs               # doGet + getDataForDashboard (google.script.run)
    Index.html                 # markup
    Stylesheet.html            # CSS responsivo (mobile-first)
    Script.html                # JS de agregação + Chart.js
.clasp.json                    # vincula ao projeto Apps Script remoto
.github/workflows/deploy.yml
```

> Todos os `.gs` rodam no mesmo escopo global do Apps Script — chamadas como `jsonResponse_()` em `webhook/Webhook.gs` resolvem para a função em `shared/Helpers.gs` sem `import`.

## Setup local (uma vez)

1. Instalar dependências:
   ```bash
   npm install
   ```
2. Login no clasp (abre navegador):
   ```bash
   npx clasp login
   ```
3. Criar o projeto Apps Script (ou usar um existente):
   ```bash
   npx clasp create --type standalone --title hook-finance --rootDir src
   ```
   Isso preenche o `scriptId` em `.clasp.json`. Se já tem um projeto, edite manualmente.
4. Criar a planilha Google Sheets que vai receber os dados. Pegue o `SHEET_ID` da URL (`https://docs.google.com/spreadsheets/d/<SHEET_ID>/edit`) e cole em [src/shared/Constants.gs](src/shared/Constants.gs). Ajuste `SHEET_NAME` se a aba não for `Sheet1`.
5. Adicione o cabeçalho na linha 1 da planilha (ver [Esquema da planilha](#esquema-da-planilha) abaixo).

## Configurar o token do webhook

No editor do Apps Script (após o primeiro `clasp push`):

1. Abra o projeto: `npx clasp open`.
2. Edite a função `setupToken` em [src/shared/Setup.gs](src/shared/Setup.gs) colocando um token forte e rode-a uma vez (botão Run). Isso grava em **Project Settings → Script Properties** a chave `WEBHOOK_TOKEN`.
3. Alternativa: vá direto em **Project Settings → Script Properties → Add script property** e crie `WEBHOOK_TOKEN` manualmente.

## Primeiro deploy (manual, para autorizar scopes)

O Apps Script exige autorização interativa antes do primeiro request:

1. No editor, **Deploy → New deployment → Web app**.
2. Execute as: **Me**, Who has access: **Anyone**.
3. Autorize os scopes (Sheets + external request).
4. Copie a **Web app URL** — é o endpoint do webhook.

## Configurar o GitHub Action

1. Crie o repositório no GitHub e faça push.
2. No GitHub: **Settings → Secrets and variables → Actions → New repository secret**:
   - Nome: `CLASPRC_JSON`
   - Valor: conteúdo do arquivo `~/.clasprc.json` (gerado pelo `clasp login`).
     ```bash
     cat ~/.clasprc.json
     ```
3. A partir daí, todo push em `main` que altere `src/**` aciona `clasp push` + `clasp deploy`.

## Esquema da planilha

A linha 1 da planilha deve ter os seguintes cabeçalhos, na ordem:

| # | Coluna | Conteúdo |
|---|---|---|
| 1 | Data | Data de fechamento da fatura (regra: dia 06 do mês seguinte ao mês atual). |
| 2 | Data Referência | Data e hora da compra extraídas do texto (`DD/MM/YYYY HH:MM`). |
| 3 | Descrição | Estabelecimento extraído do texto (ex.: `SUPERMERCADOS V`). |
| 4 | Valor | Valor numérico da compra (ex.: `32,78`). |
| 5 | Origem | Sempre `Cartão` (constante). |
| 6 | Categoria | Inferida via [Classifier](src/webhook/Classifier.gs) a partir do histórico. Vazia se não houver match suficiente. |
| 7 | Rateio | Inferido via [Classifier](src/webhook/Classifier.gs) a partir do histórico. Valores possíveis: `Julio`, `Dani`, `Metade`, `Alzira`. Vazio se não houver match suficiente. |
| 8 | Cartão | Últimos 4 dígitos do cartão extraídos do texto. Mapeamento titular em [src/shared/Constants.gs](src/shared/Constants.gs) (`CARDS`): `1018`, `9727` → Julio; `4750`, `0784` → Dani. |
| 9 | Parcela | String no formato `parcela_atual/total` (ex: `1/3` = 1ª de 3). Vazio quando à vista. Editável pelo modal da aba Lançamento via [updateEntry](src/dashboard/Dashboard.gs) — o stepper edita só o total; parcela_atual é sempre gravada como `1`. |
| 10 | Acerto | `Sim` quando a linha deve entrar no rateio do "Acerto Final". Vazio caso contrário. |

Constantes que controlam o comportamento:

- `INVOICE_CLOSING_DAY` em [src/shared/Constants.gs](src/shared/Constants.gs) — dia do fechamento da fatura (default `6`).
- `ORIGEM` em [src/shared/Constants.gs](src/shared/Constants.gs) — texto fixo da coluna Origem para webhook (default `Cartão`).
- `PURCHASE_RE` em [src/webhook/Webhook.gs](src/webhook/Webhook.gs) — regex que extrai cartão, valor, data, hora e descrição do texto.

### Classificação automática (Categoria/Rateio)

Quando uma compra de cartão chega, o webhook tenta inferir `Categoria` e `Rateio` olhando o histórico:

- Considera apenas linhas com `Origem = Cartão` que já tenham `Categoria` ou `Rateio` preenchidos.
- Calcula similaridade Jaccard entre tokens normalizados (uppercase, sem acentos, sem pontuação, sem stop-words tipo `LJ`, `FILIAL`, `BR`, `LTDA`).
- Score ≥ `CLASSIFY_THRESHOLD` (default `0.4`) → copia `Categoria` e `Rateio` da linha mais similar (empate → mais recente vence).
- Sem match suficiente → as duas colunas ficam vazias para você preencher manualmente.

Exemplo: se você classificou uma vez `"AMAZON BR"` como `Categoria = Compras / Rateio = Metade`, da próxima vez que vier `"AMAZON.COM.BR LJ 09"` o sistema completa sozinho.

Lógica em [src/webhook/Classifier.gs](src/webhook/Classifier.gs). Para tunar: ajustar `CLASSIFY_THRESHOLD` ou `CLASSIFY_STOP_WORDS`.

### Despesas fixas mensais

Quando chega a **primeira compra de cartão** de uma nova fatura (i.e., não existe nenhuma linha com `Data` = data de fechamento atual e `Origem` = `Cartão`), o webhook insere automaticamente uma lista de despesas fixas (diarista, plano de saúde, contas, condomínio, etc.) antes de gravar a compra. A lista está em [src/webhook/FixedExpenses.gs](src/webhook/FixedExpenses.gs) — edite ali para adicionar/remover/alterar valores.

### Formato esperado do `text`

```
Compra no cartão final 1018, de R$ 32,78, em 01/05/26, às 18:33, em SUPERMERCADOS V, aprovada.
```

Se o texto não casar com `PURCHASE_RE`, a linha ainda é gravada, mas as colunas 2-4 ficam vazias.

## Testar o webhook

```bash
curl -X POST "<WEB_APP_URL>" \
  -H "Content-Type: application/json" \
  -d '{"token":"<WEBHOOK_TOKEN>","title":"Compra aprovada","text":"Compra no cartão final 1018, de R$ 32,78, em 01/05/26, às 18:33, em SUPERMERCADOS V, aprovada."}'
```

Resposta esperada:
```json
{"ok":true}
```

E uma nova linha aparece na planilha com as 7 colunas preenchidas conforme o esquema acima.

### Erros possíveis

| Resposta | Causa |
|---|---|
| `{"ok":false,"error":"unauthorized"}` | `token` ausente ou diferente do `WEBHOOK_TOKEN`. |
| `{"ok":false,"error":"missing_fields"}` | `title` ou `text` vazio/ausente. |
| `{"ok":false,"error":"sheet_not_found"}` | `SHEET_NAME` não existe na planilha. |
| `{"ok":false,"error":"empty_body"}` | POST sem body JSON. |

## Dashboard

O dashboard agora roda como **PWA** em `https://polite-mushroom-0d3d07a0f.7.azurestaticapps.net/` (React + Vite + Tailwind v4 hospedado no Azure Static Web Apps). Abrir o `/exec` direto no navegador agora retorna apenas uma página de redirect.

- **Auth**: PWA pede o `WEBHOOK_TOKEN` no login. O token é validado por uma chamada GET a `lastEntries(n=1)` antes de ser salvo em `localStorage` (`hook-finance-store.token`).
- **Comunicação**: a app chama `/api/proxy?action=...` (Azure Function) que repassa para o `/exec` do Apps Script — same-origin, sem CORS no browser.
- **Endpoint JSON legado** (debug): `GET <WEB_APP_URL>?action=data&token=<TOKEN>` ainda retorna `{ok, rows[]}`.
- **Logout**: dentro da PWA, limpe `localStorage` em DevTools → `hook-finance-store` ou esqueça o token e vá direto pro login.
- **Responsivo**: mobile-first. Em ≥640px nav e os 4 tiles ficam sticky no topo; em ≥750px Consulta exibe todos os painéis simultaneamente (sem sub-tabs).

## Comandos úteis

```bash
npm run push     # clasp push -f
npm run deploy   # clasp deploy
npm run pull     # baixa do remoto (caso edite via UI)
```

### ⚠ `clasp push` / `clasp deploy` local vs. GitHub Action

`clasp push` e `clasp deploy` rodando da sua máquina enviam o conteúdo da pasta `src/` **direto pros servidores do Apps Script**, sem passar por git/GitHub. Use para iterar rápido durante desenvolvimento.

**Risco**: a produção (Apps Script) e o repo (GitHub) ficam fora de sync enquanto você não comita. Se a [GitHub Action](.github/workflows/deploy.yml) rodar a partir do último commit (push em `main`), ela vai sobrescrever a produção com a versão antiga do repo — efetivamente **revertendo** tudo que você empurrou local.

Regra prática:
1. Itere local com `npm run push` (e `npm run deploy` quando quiser atualizar a versão servida do deployment fixo).
2. Quando estabilizar, **comite e dê push em `main`** — a Action re-empurra (sem mudanças), produção e repo voltam alinhados.
3. Antes de qualquer push em `main`, confira `git status` — não pode ter divergência silenciosa entre `src/` no repo e o que tá em produção.
