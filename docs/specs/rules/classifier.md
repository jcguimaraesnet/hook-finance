---
status: stable
last_updated: 2026-05-07
---

# Classifier — sugestão de Categoria/Rateio (Apps Script)

Sugere `categoria` e `rateio` para uma compra recém-recebida pelo webhook, com base em similaridade Jaccard sobre tokens da descrição comparados com o histórico de compras já classificadas.

## Contexto

Roda **só no backend**, durante o handle do webhook. Frontend não reimplementa: PWA e Flutter não classificam — eles veem o resultado já gravado na planilha. Documentar aqui é essencial mesmo assim, porque mudanças no comportamento (threshold, stop words, normalização) afetam o que aparece no PWA/Flutter sem que sejam óbvias.

## Regras

`classifyFromHistory_(sheet, descricao) → { categoria, rateio }`:

1. Se `descricao` é vazia → retorna `{ "", "" }`.
2. Tokeniza `descricao` (ver abaixo). Se sem tokens válidos → `{ "", "" }`.
3. Lê todas as linhas existentes da planilha (cols A..G).
4. Para cada linha onde `origem === "Cartão"` E (`categoria` OU `rateio` não vazios):
   - Tokeniza a `descricao` da linha histórica.
   - Calcula Jaccard entre os dois conjuntos de tokens.
5. Pega a linha de **maior score**.
6. Se `bestScore >= 0.4` (`CLASSIFY_THRESHOLD`) → retorna `{ categoria, rateio }` da melhor linha.
7. Senão → `{ "", "" }`.

### Normalização (`normalizeForClassify_`)

```
upper → NFD → remove diacríticos → mantém só [A-Z0-9 espaço] → colapsa espaços → trim
```

### Tokenização (`tokenizeForClassify_`)

```
normaliza → split por espaço → descarta tokens com length <= 1 ou em CLASSIFY_STOP_WORDS
```

### Stop words

```
LJ, LOJA, FILIAL, BR, COM, LTDA, SA, ME, EPP, S, A
```

### Jaccard

```
inter = |A ∩ B|
score = inter / (|A| + |B| - inter)
```

Se algum dos conjuntos é vazio → 0.

## Edge cases

- **Sheet com poucos dados** (< 2 linhas após header): retorna `{ "", "" }`. Útil em primeira execução.
- **Empate de score:** retorna a **primeira** linha com score máximo encontrada na iteração (ordem da planilha, top-down). Não há tiebreaker explícito.
- **Tokens só com stop words:** `"LJ ABC LTDA"` → tokens `["ABC"]`. Bom (descarta lixo).
- **Acentos/cases:** `"Padaria"` e `"PADARIA"` produzem o mesmo token `"PADARIA"` após normalização.
- **Match sobre linhas com `categoria` mas `rateio` vazio:** retorna `{ categoria: <X>, rateio: "" }` (passa o vazio adiante; webhook insere vazio → usuário define manualmente depois pelo modal).

## Mudar o classifier

Threshold (`0.4`) foi escolhido empiricamente. Diminuir → mais classificações (mais ruído). Aumentar → menos sugestões (mais "(sem categoria)"). Stop words crescem com o tempo conforme novos lojistas aparecem com substrings genéricas. Adicionar palavra à lista é mudança trivial; revisitar quando ruído crescer.

## Implementações

- **Backend (autoritativo):** [apps-script/webhook/Classifier.gs](../../../apps-script/webhook/Classifier.gs)
- **PWA / Flutter:** N/A. Não chamam classifier.

## Specs relacionadas

- [../api/webhook.md](../api/webhook.md) — onde o classifier é invocado
- [../data/despesas-sheet.md](../data/despesas-sheet.md) — cols F (categoria), G (rateio)
