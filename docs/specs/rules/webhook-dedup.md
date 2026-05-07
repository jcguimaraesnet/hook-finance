---
status: stable
last_updated: 2026-05-07
---

# Webhook dedup

Descarta replays do webhook (mesma notificação chegando 2-3 vezes em poucos segundos) sem inserir linha duplicada na planilha.

## Contexto

O app de notificação no Android, em alguns formatos de payload, dispara o mesmo `title`+`text` 2 ou 3 vezes em sequência rápida (segundos). Sem dedup, geraria linhas duplicadas. Janela escolhida: 5 minutos — generoso para o uso real, curto o bastante para que o usuário consiga reinserir a mesma compra propositalmente esperando 5 min (raro, mas viável).

## Regras

1. **Fingerprint** = SHA-256 hex de `title + "\n" + text`. Calculado por `fingerprint_(title, text)`.
2. **Cache key** = `"wh:" + fingerprint`.
3. **Lookup:** `CacheService.getScriptCache().get(cacheKey)`.
   - Hit → retorna `{ ok: true, deduped: true }` SEM inserir.
   - Miss → segue inserção, e antes do final grava `cache.put(cacheKey, "1", 300)`.
4. **TTL:** `DEDUP_WINDOW_SECONDS = 300` segundos = 5 min.

## Edge cases

- **Notificação genuína idêntica em < 5 min** (ex.: dois lançamentos do mesmo valor no mesmo estabelecimento minutos depois): seria dedupada erroneamente. Trade-off aceito; usuário insere manualmente via Lançamento se acontecer.
- **`title` ou `text` `null`/`undefined`:** `(title || "")` e `(text || "")` no hash — funciona, hash determinístico.
- **CacheService limpo por restart do Apps Script:** dedup window pode ser zerada raramente. Sem garantia de persistência.

## Implementações

- **Backend (autoritativo):** [apps-script/webhook/Webhook.gs:6,29-36,78-89](../../../apps-script/webhook/Webhook.gs)
- **PWA / Flutter:** N/A.

## Specs relacionadas

- [../api/webhook.md](../api/webhook.md)
