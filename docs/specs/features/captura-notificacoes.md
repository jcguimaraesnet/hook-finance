---
status: draft
last_updated: 2026-05-11
---

# Captura de notificações (Android, Flutter)

Feature que lê notificações de outros apps (cartão de banco) e POSTa no webhook do hook-finance — substitui o Tasker/IFTTT externo.

## Contexto

O caminho atual: app de cartão (ex.: Nubank) dispara notificação push → Tasker (app externo) intercepta → POST `{title, text, token}` em `/api/proxy` → backend grava na planilha. Funciona, mas depende de app de terceiros e configuração à parte.

Esta feature traz o mesmo fluxo pra dentro do APK Flutter, configurável pelo usuário em **Configurações → Captura de notificações** (gear icon no header da Início).

Limitação: Apple não permite que apps leiam notificações de outros apps. Esta feature é Android-only. iOS continua dependendo da entrada manual via aba "+ Novo".

## Regras

### Plataforma e permissão

1. Disponível apenas em `Platform.isAndroid` (e `!kIsWeb`). Em iOS/web, a tela de Configurações renderiza um aviso e desabilita o toggle.
2. Requer permissão `BIND_NOTIFICATION_LISTENER_SERVICE`, concedida pelo usuário em **Configurações do sistema → Apps → Acesso especial → Acesso à notificação → Hook Finance**. O app NÃO pode forçar a concessão programaticamente.
3. O plugin [`notification_listener_service`](https://pub.dev/packages/notification_listener_service) v0.3.x faz a ponte. Service declarado em [AndroidManifest.xml](../../../app/android/app/src/main/AndroidManifest.xml) com `name="notification.listener.service.NotificationListener"`.

### Configuração (persistida em SharedPreferences)

| Chave | Tipo | Default | Notas |
|---|---|---|---|
| `nc_enabled` | bool | `false` | Liga/desliga a captura. |
| `nc_package` | string | `""` | Package name do app a escutar (ex.: `com.nu.production`). Sem default — usuário escolhe via app picker. |
| `nc_title_regex` | string | `""` | Regex (opcional) aplicada ao `title` da notificação. Vazio = sem filtro. Regex inválida é tratada como sem filtro (não bloqueia). |
| `nc_last_capture_ms` | int | — | Timestamp da última captura bem-sucedida. |
| `nc_last_capture_title` | string | — | Título da última captura. |

`nc_last_error` é mantido só em memória (não persiste).

### Filtragem de eventos

Para cada `ServiceNotificationEvent` recebido:

1. Se `event.hasRemoved == true` → ignora (não dispara em remoções).
2. Se `event.packageName != config.packageName` → ignora.
3. Se `config.titleRegex` não-vazia:
   - Tenta compilar a regex. Se compilação falha, pula o filtro (logs no debug).
   - Se compila e não casa com `event.title`, ignora.
4. Se `title` E `content` ambos vazios → ignora.
5. Resto: POSTa.

### POST no backend

Reusa `ApiClient.post()` (mesmo cliente do resto da app, já tem o token persistido). Body enviado:

```json
{
  "action": "webhookFromApp",
  "token": "<WEBHOOK_TOKEN>",
  "title": "<event.title>",
  "text": "<event.content>"
}
```

O Apps Script (`Dashboard.gs` doPost) detecta `title+text` e despacha pro webhook handler — `action` é ignorada nesse caminho. Mesmo handler do Tasker, mesmo dedup de 5min via `fingerprint_(title, text)`.

### Status (mostrado na tela de Settings)

- **Última captura**: `lastCaptureAt` formatado relativo (ex.: "há 2 min").
- **Título capturado**: `lastCaptureTitle`.
- **Erro**: `lastError` se houver — vermelho.

### App picker

- Bottom sheet via `installed_apps` v2.x.
- Lista apps não-system, launchable, com ícone.
- Busca textual sobre `name` + `packageName` (case-insensitive).
- Tap → grava `packageName` em SharedPreferences.

Permissão Android: `QUERY_ALL_PACKAGES` (declarada com `tools:ignore` — sensível pro Play Store mas OK pra distribuição sideload).

## Edge cases

- **App fechado pelo usuário (swipe-away)**: o stream do plugin depende do isolate Flutter estar vivo. Quando o processo é morto, captura para. Não há background isolate na v1 — limitação conhecida, documentada na tela de Settings. Mitigação: deixar Tasker em paralelo como backup.
- **Permissão revogada manualmente em sistema**: o controller verifica `isPermissionGranted` antes de assinar o stream. Se revogada, listener não inicia; toggle pode ficar "Ativar captura: on" mas sem capturar. Voltar pra tela de Settings revalida (lifecycle `resumed`).
- **Regex inválida**: tratada como sem filtro (não bloqueia POST). Decisão deliberada — preferimos sobre-capturar a perder eventos por erro de digitação.
- **Backend retorna `deduped:true`**: contado como sucesso (atualiza `lastCaptureAt`). O dedup serve pra dedup do app de cartão (replays), e funciona pra Tasker E pra essa feature simultaneamente.
- **Notificação sem `title` ou sem `content`**: se ambos vazios, ignora. Se um deles preenchido, envia mesmo assim (backend pode rejeitar via `missing_fields` — caso fica em `lastError`).
- **Concurrent toggle de config**: o controller reassina o stream sempre que `enabled|packageName|titleRegex` muda (via `ref.listen`).

## Histórico de capturas

Persiste as últimas 50 capturas (sucesso ou erro) em `<app_documents_dir>/capture_history.json` via `path_provider`. Eventos descartados pelos filtros (regex/package/empty title+content) **não** entram — o histórico é "o que tentou ir pro webhook", não "o que chegou no listener".

### Schema

Array JSON, mais recente em primeiro lugar (append-front, trim para 50):

```json
[
  {
    "ts": 1715441234567,
    "package": "com.nu.production",
    "title": "Compra aprovada",
    "content": "R$ 42,50 em MERCADO",
    "status": "ok",
    "error": null
  }
]
```

- `ts` (int): `DateTime.now().millisecondsSinceEpoch` no momento do POST.
- `package`: `event.packageName` (deveria bater com `config.packageName`).
- `title`, `content`: texto cru da notificação.
- `status`: `"ok"` (backend retornou ok ou dedup) ou `"error"` (exception ou ok=false).
- `error`: mensagem em caso de erro (`"Backend: <code>"` ou `"<exception>"`); `null` se ok.

### Provider

`captureHistoryProvider` em [app/lib/state/capture_history_provider.dart](../../../app/lib/state/capture_history_provider.dart) — `AsyncNotifierProvider<CaptureHistoryNotifier, List<CaptureLogEntry>>`. Métodos:

- `build()` — lê o arquivo; vazio se não existir; vazio se JSON inválido (best-effort).
- `append(entry)` — prepend, trim para 50, atualiza state, escreve arquivo. Write é best-effort (swallow); state em memória é sempre autoritativo.
- `clear()` — state vazio, deleta arquivo.

### UI

Tela `/settings/captures` (rota filha de `/` em `app.dart`). Renderiza:
- Header com botão `delete_sweep_outlined` no slot `trailing` — só aparece quando há entries; abre confirmação antes de chamar `clear`.
- Lista de `BloomCard`s, uma por entry: ícone status, título (ou "(sem título)"), `relativeTime(when)` no canto direito, content em 2 linhas com ellipsis, mensagem de erro em vermelho se `status="error"`.
- Empty state com `Icons.history_outlined` + texto orientativo.

Entry-point: `TextButton.icon "Ver histórico"` no rodapé do `_StatusCard` da `SettingsPage`.

### Web (PWA)

`path_provider` não suporta `getApplicationDocumentsDirectory()` no web. `_file()` retorna `null` em `kIsWeb` → `build` retorna `[]`; `append`/`clear` são no-op. Como a feature em si já é Android-only, a tela `/settings/captures` no web sempre mostra empty state.

## Implementações

- **Provider/state:** [app/lib/state/notification_capture_provider.dart](../../../app/lib/state/notification_capture_provider.dart) — `NotificationCaptureNotifier` + `notificationCaptureControllerProvider`.
- **UI Settings:** [app/lib/features/settings/settings_page.dart](../../../app/lib/features/settings/settings_page.dart).
- **App picker:** [app/lib/features/settings/app_picker_sheet.dart](../../../app/lib/features/settings/app_picker_sheet.dart).
- **Manifest:** [app/android/app/src/main/AndroidManifest.xml](../../../app/android/app/src/main/AndroidManifest.xml) — service NLS + permissões.
- **Rota:** [app/lib/app.dart](../../../app/lib/app.dart) — `/settings`.
- **Trigger UI:** [app/lib/features/inicio/inicio_page.dart](../../../app/lib/features/inicio/inicio_page.dart) — gear icon ao lado do refresh.
- **Backend (inalterado):** [apps-script/webhook/Webhook.gs](../../../apps-script/webhook/Webhook.gs) — mesmo handler que o Tasker usa.
- **Histórico (provider):** [app/lib/state/capture_history_provider.dart](../../../app/lib/state/capture_history_provider.dart)
- **Histórico (model):** [app/lib/state/capture_log_entry.dart](../../../app/lib/state/capture_log_entry.dart)
- **Histórico (UI):** [app/lib/features/settings/captures_history_page.dart](../../../app/lib/features/settings/captures_history_page.dart)

## Roadmap

- **v1 (este)**: foreground-only. Funciona enquanto app está em recents. Tasker mantido em paralelo.
- **v2 (futuro)**: background isolate via `flutter_foreground_task` ou native Kotlin POST direto (sem depender do isolate Flutter). Permitiria desligar Tasker totalmente.

## Specs relacionadas

- [../api/webhook.md](../api/webhook.md) — handler que recebe os POSTs.
- [../rules/webhook-dedup.md](../rules/webhook-dedup.md) — janela de 5min.
- [../rules/webhook-parser.md](../rules/webhook-parser.md) — PURCHASE_RE que extrai os campos.
