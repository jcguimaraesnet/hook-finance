# hook-finance

Webhook em Google Apps Script que recebe `POST` com `title` e `text` no body e grava uma nova linha em uma Google Sheet. Deploy automatizado via GitHub Actions com [`clasp`](https://github.com/google/clasp).

**Projeto Apps Script**: https://script.google.com/home/projects/1HvwjDc_t-XIi1SmZnq5gxrZoTBEw7GlDx98d-UolqRAQBk0BBvGwz9E1/edit

**Webhook (POST)**: https://script.google.com/macros/s/AKfycby7v9mrOGHV6tIaiOmgs7ZaGolmSTXsEKIj3rYjBlYalePcuBmSM0C35Wc5-vJZRNE-7Q/exec

## Estrutura

```
src/
  Code.gs           # doPost handler
  appsscript.json   # manifest (scopes + webapp config)
.clasp.json         # vincula ao projeto Apps Script remoto
.github/workflows/deploy.yml
```

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
4. Criar a planilha Google Sheets que vai receber os dados. Pegue o `SHEET_ID` da URL (`https://docs.google.com/spreadsheets/d/<SHEET_ID>/edit`) e cole em `src/Code.gs`. Ajuste `SHEET_NAME` se a aba não for `Sheet1`.
5. Sugerido: adicione cabeçalho na linha 1 da planilha — `timestamp | title | text`.

## Configurar o token do webhook

No editor do Apps Script (após o primeiro `clasp push`):

1. Abra o projeto: `npx clasp open`.
2. Edite a função `setupToken_` em `Code.gs` colocando um token forte e rode-a uma vez (botão Run). Isso grava em **Project Settings → Script Properties** a chave `WEBHOOK_TOKEN`.
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

## Testar o webhook

```bash
curl -X POST "<WEB_APP_URL>" \
  -H "Content-Type: application/json" \
  -d '{"token":"<WEBHOOK_TOKEN>","title":"Teste","text":"Conteudo"}'
```

Resposta esperada:
```json
{"ok":true}
```

E uma nova linha aparece na planilha com `timestamp`, `title`, `text`.

### Erros possíveis

| Resposta | Causa |
|---|---|
| `{"ok":false,"error":"unauthorized"}` | `token` ausente ou diferente do `WEBHOOK_TOKEN`. |
| `{"ok":false,"error":"missing_fields"}` | `title` ou `text` vazio/ausente. |
| `{"ok":false,"error":"sheet_not_found"}` | `SHEET_NAME` não existe na planilha. |
| `{"ok":false,"error":"empty_body"}` | POST sem body JSON. |

## Comandos úteis

```bash
npm run push     # clasp push -f
npm run deploy   # clasp deploy
npm run pull     # baixa do remoto (caso edite via UI)
```
