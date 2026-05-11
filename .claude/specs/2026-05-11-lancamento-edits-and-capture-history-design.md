---
status: approved
last_updated: 2026-05-11
---

# Edição expandida de lançamento + histórico de capturas

Quatro ajustes na app Flutter (APK + PWA), originados da conversa com o usuário em 2026-05-11.

## Contexto

Hoje:

- O **modal de edição** (`app/lib/features/lancamento/edit_dialog.dart`) exibe `Data de referência` (col B) e `Origem` (col E) como **read-only**, e **não exibe** col A `Data` (fechamento de fatura).
- A página **Lançamentos** (`app/lib/features/lancamento/lancamento_page.dart`) não tem `RefreshIndicator` — a Início já tem.
- A feature **Captura de notificações** (`app/lib/state/notification_capture_provider.dart`) persiste **só a última** captura (1 título + 1 timestamp). Não há histórico navegável.
- O **backend `updateEntry`** (`apps-script/dashboard/Dashboard.gs:337`) escreve só cols C (descricao), D (valor), F (categoria), G (rateio), I (parcela). Não escreve cols A, B, E.

Os quatro ajustes:

1. Permitir edição de `Origem` e `Data Referência` no modal.
2. Adicionar campo **Mês Fatura** (col A `Data`) no modal, exibido como `mês de YYYY` mas editável (preserva o dia).
3. Pull-to-refresh na página Lançamentos.
4. Tela de histórico de capturas de notificação, linkada a partir do card STATUS em Configurações.

## Regras

### 1. Modal de edição — novos campos editáveis

**Ordem dos campos no modal** (cima → baixo):

1. **Mês Fatura** (col A `Data`) — NOVO
2. **Data Referência** (col B `dataRef`) — antes read-only, agora editável
3. **Origem** (col E) — antes read-only, agora editável
4. Descrição
5. Valor (R$)
6. Categoria
7. Rateio
8. Parcela

#### 1.1 Mês Fatura (col A)

- **Display**: read-only mostrando `monthYearShort(entry.data)` (helper existente em `core/format/dates.dart`) → ex. `"maio de 2026"`.
- **Tap**: abre `showDatePicker`:
  - `initialDate = parseBrDate(entry.data)` (helper existente).
  - `firstDate = DateTime(2020, 1, 1)`, `lastDate = DateTime.now().add(Duration(days: 365 * 2))`.
  - `locale = Locale('pt', 'BR')` (já que a app usa Material 3 + intl; setado via `MaterialApp.supportedLocales`/`localizationsDelegates` — verificar e ajustar `app.dart` se necessário).
- **Após escolha**: armazena `DD/MM/YYYY` da data inteira escolhida. Mantém o DD escolhido pelo usuário (decisão: usuário deve poder ajustar o dia de fechamento explicitamente; não force o INVOICE_CLOSING_DAY).
- **Send**: campo `data` em `UpdateEntryFields`.

#### 1.2 Data Referência (col B)

- **Display**: read-only mostrando `entry.dataRef` (`"DD/MM/YYYY HH:MM"`) — mostra na íntegra.
- Linha tem dois sub-botões: `[📅 dia]` e `[🕐 hora]`.
- **Tap em dia**: abre `showDatePicker` com `initialDate` do componente data atual.
- **Tap em hora**: abre `showTimePicker` com `initialTime` do componente hora atual.
- **Após escolha**: reconstrói `"DD/MM/YYYY HH:MM"`.
- **Helpers novos** em `app/lib/core/format/dates.dart`:
  - `DateTime parseBrDateTime(String s)` — `"DD/MM/YYYY HH:MM"` → DateTime. Fallback `DateTime.fromMillisecondsSinceEpoch(0)`.
  - `String formatBrDate(DateTime d)` — DateTime → `"DD/MM/YYYY"`.
  - `String formatBrDateTime(DateTime d)` — DateTime → `"DD/MM/YYYY HH:MM"`.
- **Send**: campo `dataRef` em `UpdateEntryFields`.

#### 1.3 Origem (col E)

- **UI**: `DropdownButtonFormField<String>` (matching o widget de Rateio no mesmo modal).
- **Opções** (matching `ADD_ENTRY_ORIGEMS` em `Dashboard.gs:256`):
  - `"Cartão"`
  - `"Pix (contas)"`
  - `"Pessoal"`
  - `"Empregados"`
  - `"Contas"`
- **Send**: campo `origem` em `UpdateEntryFields`.

#### 1.4 `UpdateEntryFields` (Dart) — novos campos

Em `app/lib/core/types.dart`:

```dart
class UpdateEntryFields {
  final String descricao;
  final double valor;
  final String categoria;
  final String rateio;
  final String parcela;
  // NOVOS:
  final String data;       // "DD/MM/YYYY"
  final String dataRef;    // "DD/MM/YYYY HH:MM"
  final String origem;     // enum

  const UpdateEntryFields({
    required this.descricao,
    required this.valor,
    required this.categoria,
    required this.rateio,
    required this.parcela,
    required this.data,
    required this.dataRef,
    required this.origem,
  });

  Map<String, dynamic> toJson() => {
        'descricao': descricao,
        'valor': valor,
        'categoria': categoria,
        'rateio': rateio,
        'parcela': parcela,
        'data': data,
        'dataRef': dataRef,
        'origem': origem,
      };
}
```

Todos os campos são obrigatórios — o cliente sempre envia o valor atual lido do form (que veio do `Entry`). Sem branching no servidor.

### 2. Backend — `updateEntry` estendido

Em `apps-script/dashboard/Dashboard.gs`, função `updateEntry`:

- Validar `fields.origem` contra `ADD_ENTRY_ORIGEMS` (mesma constante já usada em `addEntry`). Erro `"invalid_origem"` se não bater.
- Validar `fields.data` e `fields.dataRef` como strings não-vazias. Erro `"missing_data"` / `"missing_dataRef"` se vazias.
- Escrever:
  - col 1 (A, Data): `String(fields.data)`.
  - col 2 (B, Data Referência): `String(fields.dataRef)`.
  - col 5 (E, Origem): `String(fields.origem)`.
- Manter `setNumberFormat("@")` na col B antes do setValue (mesma proteção da col I) — Sheets pode interpretar `"11/05/2026 14:32"` como datetime e mudar o formato.

Sem retrocompatibilidade: o único cliente é a Flutter app, que vai migrar junto.

### 3. Pull-to-refresh em Lançamentos

Em `app/lib/features/lancamento/lancamento_page.dart`:

- Envolver o `SingleChildScrollView` raiz em `RefreshIndicator(color: BloomColors.violet, onRefresh: _onRefresh)`.
- Forçar `physics: const AlwaysScrollableScrollPhysics()` no `SingleChildScrollView` (sem isso, o RefreshIndicator não dispara quando o conteúdo cabe na viewport).
- Converter `_LancamentoPageState` em quem detém o handler (já é `ConsumerStatefulWidget`).
- `_onRefresh`:
  ```dart
  Future<void> _onRefresh() async {
    if (_refreshing) return;
    setState(() => _refreshing = true);
    final messenger = ScaffoldMessenger.of(context);
    ref.invalidate(lastEntriesProvider);
    ref.invalidate(monthDataProvider);
    String? error;
    try {
      await Future.wait<void>([
        ref.read(lastEntriesProvider(10).future),
        ref.read(monthDataProvider(null).future),
      ]);
    } catch (e) { error = '$e'; }
    if (!mounted) return;
    setState(() => _refreshing = false);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(
      content: Text(error == null ? 'Atualizado' : 'Falha ao atualizar: $error'),
      duration: const Duration(seconds: 2),
      behavior: SnackBarBehavior.floating,
      backgroundColor: error == null ? BloomColors.ink : BloomColors.bad,
    ));
  }
  ```
- O RefreshIndicator fica no nível da página, então funciona tanto na aba `Lançamentos` quanto `+ Novo`. Em `+ Novo` o refresh só re-puxa `monthDataProvider` (usado pelo autocomplete de Categoria), o que é benigno.

### 4. Histórico de capturas de notificação

#### 4.1 Persistência

- Arquivo `app_documents_dir/capture_history.json` via `path_provider`.
  - Adicionar `path_provider: ^2.1.4` em `app/pubspec.yaml` como dep direta (verificar `pub get` na execução; se houver lock mais novo, usar a versão compatível atual).
- Schema:
  ```json
  [
    {
      "ts": 1715441234567,
      "package": "com.nu.production",
      "title": "Compra aprovada",
      "content": "R$ 42,50 em MERCADO EXTRA",
      "status": "ok",
      "error": null
    }
  ]
  ```
  - `ts`: `DateTime.now().millisecondsSinceEpoch`.
  - `package`: `event.packageName`.
  - `title`, `content`: vindos do `ServiceNotificationEvent`.
  - `status`: `"ok"` (backend retornou ok ou `deduped`) | `"error"` (exception ou backend retornou ok=false).
  - `error`: string da mensagem de erro, ou `null` se ok.

#### 4.2 Retenção

- **50 itens**, mais recente em primeiro lugar (append-front).
- Quando passar de 50, descarta o mais antigo (cauda da lista).

#### 4.3 Que eventos entram

- Apenas eventos que **passaram** os filtros (regex de título + package match + não-vazio) e tentaram POST no webhook.
- Eventos descartados em early-return (regex sem match, package errado, ambos vazios) **não** entram. Razão: o usuário pediu "histórico de capturas", não "log de tudo que chegou". Mantém a lista relevante.

#### 4.4 Modelo (Dart)

Novo arquivo `app/lib/state/capture_log_entry.dart`:

```dart
class CaptureLogEntry {
  final int ts;
  final String package;
  final String title;
  final String content;
  final String status; // 'ok' | 'error'
  final String? error;

  const CaptureLogEntry({
    required this.ts,
    required this.package,
    required this.title,
    required this.content,
    required this.status,
    this.error,
  });

  Map<String, dynamic> toJson() => {
        'ts': ts,
        'package': package,
        'title': title,
        'content': content,
        'status': status,
        'error': error,
      };

  factory CaptureLogEntry.fromJson(Map<String, dynamic> j) => CaptureLogEntry(
        ts: (j['ts'] as num?)?.toInt() ?? 0,
        package: (j['package'] ?? '') as String,
        title: (j['title'] ?? '') as String,
        content: (j['content'] ?? '') as String,
        status: (j['status'] ?? 'ok') as String,
        error: j['error'] as String?,
      );

  DateTime get when => DateTime.fromMillisecondsSinceEpoch(ts);
}
```

#### 4.5 Provider

Novo `captureHistoryProvider` em `app/lib/state/capture_history_provider.dart`:

- `AsyncNotifierProvider<CaptureHistoryNotifier, List<CaptureLogEntry>>`.
- `build()` → lê arquivo, retorna lista (ou `[]` se inexistente).
- `Future<void> append(CaptureLogEntry e)` → prepend, trim para 50, escreve arquivo, atualiza state.
- `Future<void> clear()` → escreve `[]`, atualiza state.

Integração com `_handleEvent` em `notification_capture_provider.dart`:

- Após `notifier.markCapture(...)` ou `notifier.setError(...)`, chama `ref.read(captureHistoryProvider.notifier).append(...)` com status apropriado.
- O `_handleEvent` recebe um `Ref` — provider acessível por essa via.

#### 4.6 Tela `/settings/captures`

Novo arquivo `app/lib/features/settings/captures_history_page.dart`:

- `BloomScreen` + `ScreenHeader(title: 'Histórico de capturas', showBack: true)`.
- Action no header (ícone à direita): `IconButton(Icons.delete_sweep_outlined)` que abre confirmação e chama `captureHistoryProvider.notifier.clear()`.
- Body: `ListView.builder` de `BloomCard`s, espaçamento 8px.
  - Cada card:
    - Linha 1: `Icon(Icons.check_circle, BloomColors.good)` ou `Icon(Icons.error_outline, BloomColors.bad)` + título (bold) + timestamp relativo à direita (`há 2 min`/`há 1h`/`há 3d`).
    - Linha 2: `content` em `Text` com `maxLines: 2, overflow: ellipsis`. Cor `BloomColors.muted`.
    - Linha 3 (só se status=error): mensagem de erro em `BloomColors.bad`, `fontSize: 11.5`.
- Empty state: card centralizado com ícone `Icons.history_outlined` e texto `"Nenhuma captura ainda. Ative no card acima e aguarde uma notificação."`.

Função utilitária `_formatRelative(DateTime)` já existe inline na `SettingsPage` — extrair para `app/lib/core/format/dates.dart` como `String relativeTime(DateTime when)` e reusar.

#### 4.7 Entry-point na Settings

Em `app/lib/features/settings/settings_page.dart`, dentro do `_StatusCard`:

- Adicionar no rodapé do card (após o bloco de erro, antes do fechamento da Column):
  ```
  Padding(
    padding: EdgeInsets.only(top: 12),
    child: Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: () => context.go('/settings/captures'),
        icon: Icon(Icons.list_alt, size: 18),
        label: Text('Ver histórico'),
        style: TextButton.styleFrom(foregroundColor: BloomColors.violet),
      ),
    ),
  ),
  ```
- `_StatusCard` vai precisar virar `StatelessWidget` com acesso ao `context` (já tem) — push do `go` é simples.

#### 4.8 Rota

Em `app/lib/app.dart`, adicionar como filha de `/`:

```dart
GoRoute(
  path: 'settings/captures',
  builder: (_, _) => const CapturesHistoryPage(),
),
```

## Edge cases

### Modal de edição

- **`entry.data` vazio**: `parseBrDate("")` retorna `DateTime(1970,1,1)`. O picker abre nessa data. Não-blocking — usuário escolhe data nova e segue.
- **`entry.dataRef` vazio ou inválido**: `parseBrDateTime` retorna `DateTime(1970)`. UI mostra `"01/01/1970 00:00"` — sinal visual claro de que precisa corrigir.
- **Locale pt-BR no picker**: se `MaterialApp` não tiver `localizationsDelegates` configurado, os pickers vão renderizar em inglês. Verificar `app.dart` e adicionar `GlobalMaterialLocalizations.delegate`, `GlobalWidgetsLocalizations.delegate`, `GlobalCupertinoLocalizations.delegate` + `supportedLocales: [Locale('pt', 'BR'), Locale('en')]` se faltarem. Adicionar `flutter_localizations` em `pubspec.yaml` se não estiver presente.
- **Origem inválida vinda da planilha** (ex.: spelling antigo): o `Entry.origem` pode não bater com nenhum item do dropdown. Decisão: se `entry.origem` não está em `ADD_ENTRY_ORIGEMS`, default do dropdown vira o valor cru de `entry.origem` adicionado como item extra com prefixo `"(?) "`. Usuário pode trocar pra um valor válido ou manter — se manter, backend rejeita com `invalid_origem` e UI mostra erro. Alternativa mais agressiva: default `"Cartão"`. **Escolha**: mostrar valor cru como item extra — preserva info, força usuário a corrigir.

### Pull-to-refresh

- **Tap rápido durante refresh**: o flag `_refreshing` previne duplicação.
- **Erro de rede**: snackbar vermelho. Estado anterior do cache permanece (Riverpod invalidate retorna o valor anterior até a nova chamada terminar).

### Histórico de capturas

- **Arquivo corrompido** (JSON inválido): `build()` retorna `[]` e sobrescreve no próximo append. Não trava o app.
- **Write race**: dois eventos chegando simultaneamente — Notifier é serial por design do Riverpod, então o segundo `append` espera o primeiro. Mesmo assim, o write é "ler-modificar-escrever" no provider; em prática o gap é micro-segundos. Aceitável pra v1.
- **Storage cheio**: improvável com 50 itens. Sem mitigação.
- **Limpar histórico**: confirmação via `AlertDialog`. Após confirmar, lista vai a 0.
- **Web (PWA)**: `path_provider` não suporta `getApplicationDocumentsDirectory()` no web. Decisão: a feature de captura já é Android-only; no web o `captureHistoryProvider` retorna lista vazia constante e `append` é no-op. Tela `/settings/captures` mostra empty state.

## Documentação a atualizar (após implementação)

- `docs/specs/pages/lancamento.md` — seção "Modal de edição": move `Data Referência` e `Origem` de read-only para editável; adiciona `Mês Fatura` no topo.
- `docs/specs/features/captura-notificacoes.md` — adiciona seção "Histórico de capturas" com schema, retenção 50, UI da tela, rota, entry-point.
- `docs/specs/api/endpoints.md` — `updateEntry`: contrato agora inclui `data`, `dataRef`, `origem`. Validação espelha `addEntry`.

## Implementações (paths)

### Frontend (Flutter)

- `app/lib/core/types.dart` — `UpdateEntryFields` ganha `data`, `dataRef`, `origem`.
- `app/lib/core/format/dates.dart` — adiciona `parseBrDateTime`, `formatBrDate`, `formatBrDateTime`, `relativeTime`.
- `app/lib/features/lancamento/edit_dialog.dart` — refatora pra editar `data`/`dataRef`/`origem`; remove `_ReadOnlyField` (não usado mais).
- `app/lib/features/lancamento/lancamento_page.dart` — wraps em `RefreshIndicator`.
- `app/lib/state/capture_log_entry.dart` (novo) — modelo.
- `app/lib/state/capture_history_provider.dart` (novo) — provider.
- `app/lib/state/notification_capture_provider.dart` — `_handleEvent` chama `captureHistoryProvider.append`.
- `app/lib/features/settings/captures_history_page.dart` (novo) — tela.
- `app/lib/features/settings/settings_page.dart` — botão "Ver histórico" no STATUS card.
- `app/lib/app.dart` — adiciona rota `/settings/captures`. Verifica/adiciona localizationsDelegates.
- `app/pubspec.yaml` — adiciona `path_provider`. Possivelmente `flutter_localizations` se faltar.

### Backend (Apps Script)

- `apps-script/dashboard/Dashboard.gs` — `updateEntry` estendido com validação + write nas cols A/B/E.

## Specs relacionadas

- [docs/specs/pages/lancamento.md](../../docs/specs/pages/lancamento.md)
- [docs/specs/features/captura-notificacoes.md](../../docs/specs/features/captura-notificacoes.md)
- [docs/specs/api/endpoints.md](../../docs/specs/api/endpoints.md)
- [docs/specs/data/despesas-sheet.md](../../docs/specs/data/despesas-sheet.md)
