# Edição expandida de lançamento + histórico de capturas — Plano de Implementação

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Tornar Origem/Data Referência/Mês Fatura editáveis no modal de lançamento, adicionar pull-to-refresh em Lançamentos, e expor um histórico das últimas 50 capturas de notificação a partir da tela de Configurações.

**Architecture:** Quatro mudanças concêntricas. Começa pelo backend (`updateEntry` no Apps Script ganha 3 colunas) e desce pra UI (modal, página, histórico). Histórico de capturas usa um arquivo JSON em `getApplicationDocumentsDirectory()` via `path_provider`, exposto por um `AsyncNotifierProvider` do Riverpod. Tela nova `/settings/captures` listada via `GoRoute`. Pickers nativos (`showDatePicker`, `showTimePicker`) com locale pt-BR habilitado via `flutter_localizations`.

**Tech Stack:** Flutter 3.x + Riverpod 2 + GoRouter + intl + `path_provider`. Backend: Google Apps Script. Testes: `flutter_test` (pure-function) — UI/provider validados por smoke test manual no APK.

**Spec:** [.claude/specs/2026-05-11-lancamento-edits-and-capture-history-design.md](../specs/2026-05-11-lancamento-edits-and-capture-history-design.md)

---

## File Structure (a tocar)

**Backend (Apps Script):**
- Modify: `apps-script/dashboard/Dashboard.gs` — `updateEntry` valida + escreve cols A, B, E.

**Frontend (Flutter):**
- Modify: `app/lib/core/types.dart` — `UpdateEntryFields` ganha `data`, `dataRef`, `origem`.
- Modify: `app/lib/core/format/dates.dart` — adiciona `parseBrDateTime`, `formatBrDate`, `formatBrDateTime`, `relativeTime`.
- Modify: `app/lib/app.dart` — `localizationsDelegates` + `supportedLocales`. Rota `/settings/captures`.
- Modify: `app/lib/features/lancamento/edit_dialog.dart` — campos editáveis novos.
- Modify: `app/lib/features/lancamento/lancamento_page.dart` — `RefreshIndicator`.
- Create: `app/lib/state/capture_log_entry.dart` — modelo.
- Create: `app/lib/state/capture_history_provider.dart` — provider.
- Modify: `app/lib/state/notification_capture_provider.dart` — `_handleEvent` grava no histórico.
- Create: `app/lib/features/settings/captures_history_page.dart` — tela.
- Modify: `app/lib/features/settings/settings_page.dart` — botão "Ver histórico" + extrai `_formatRelative`.
- Modify: `app/pubspec.yaml` — `path_provider`, `flutter_localizations`.

**Tests:**
- Modify: `app/test/core/format/dates_test.dart` — testa novos helpers.
- Create: `app/test/state/capture_log_entry_test.dart` — testa serialização.

**Docs:**
- Modify: `docs/specs/pages/lancamento.md` (incluir paginação na seção de lista — Task 14)
- Modify: `docs/specs/features/captura-notificacoes.md`
- Modify: `docs/specs/api/endpoints.md`

---

## Task 1: Backend — `updateEntry` aceita `data`, `dataRef`, `origem`

**Files:**
- Modify: `apps-script/dashboard/Dashboard.gs:337-355`

- [ ] **Step 1: Editar `updateEntry` com validação e writes adicionais**

Substituir o corpo de `updateEntry` por:

```javascript
function updateEntry(token, row, fields) {
  const auth = checkToken_(token);
  if (auth) return auth;
  if (!row || row < 2) return { ok: false, error: "invalid_row" };
  const sheet = SpreadsheetApp.openById(SHEET_ID).getSheetByName(SHEET_NAME);
  if (!sheet) return { ok: false, error: "sheet_not_found" };
  if (row > sheet.getLastRow()) return { ok: false, error: "row_out_of_range" };
  fields = fields || {};

  const data = String(fields.data || "").trim();
  if (!data) return { ok: false, error: "missing_data" };

  const dataRef = String(fields.dataRef || "").trim();
  if (!dataRef) return { ok: false, error: "missing_dataRef" };

  const origem = String(fields.origem || "").trim();
  if (!origem) return { ok: false, error: "missing_origem" };
  if (ADD_ENTRY_ORIGEMS.indexOf(origem) < 0) return { ok: false, error: "invalid_origem" };

  // Colunas: A=data(1), B=dataRef(2), C=descricao(3), D=valor(4), E=origem(5),
  // F=categoria(6), G=rateio(7), I=parcela(9)
  sheet.getRange(row, 1).setValue(data);

  // Força TEXT na col B pra evitar auto-parse pra datetime do Sheets.
  const dataRefCell = sheet.getRange(row, 2);
  dataRefCell.setNumberFormat("@");
  dataRefCell.setValue(dataRef);

  sheet.getRange(row, 3).setValue(String(fields.descricao || ""));
  sheet.getRange(row, 4).setValue(Number(fields.valor) || 0);
  sheet.getRange(row, 5).setValue(origem);
  sheet.getRange(row, 6).setValue(String(fields.categoria || ""));
  sheet.getRange(row, 7).setValue(String(fields.rateio || ""));

  // Força TEXT na col I (Parcela) pra evitar auto-parse de "1/3" como data.
  const parcelaCell = sheet.getRange(row, 9);
  parcelaCell.setNumberFormat("@");
  parcelaCell.setValue(String(fields.parcela || ""));

  return { ok: true, row: row };
}
```

- [ ] **Step 2: Push pro Apps Script**

Run: `./node_modules/.bin/clasp.cmd push -f` (do dir raiz do repo; o `.clasp.json` aponta pra `apps-script/`).
Expected output (formato): `└─ apps-script/dashboard/Dashboard.gs` + outras files, no errors. Aceitar prompt se houver.

Alternativa CI: commit + push pra `main` dispara `deploy-apps-script.yml`.

- [ ] **Step 3: Smoke test manual (curl ou Sheet)**

Editar uma linha qualquer pelo modal (depois do Task 5) ou via curl:
```bash
curl -X POST "$APPS_SCRIPT_URL" -H "Content-Type: application/json" -d '{
  "action":"updateEntry","token":"<token>","row":2,
  "fields":{"data":"11/05/2026","dataRef":"11/05/2026 14:32","descricao":"TESTE",
            "valor":1.0,"origem":"Cartão","categoria":"","rateio":"","parcela":""}
}'
```
Expected: `{"ok":true,"row":2}` e a planilha mostra `11/05/2026` na col A, `11/05/2026 14:32` na col B (como texto), `Cartão` na col E.

- [ ] **Step 4: Commit**

```bash
git add apps-script/dashboard/Dashboard.gs
git commit -m "feat(api): updateEntry aceita data, dataRef, origem"
```

---

## Task 2: Dart — `UpdateEntryFields` ganha novos campos

**Files:**
- Modify: `app/lib/core/types.dart:174-196`

- [ ] **Step 1: Substituir a classe `UpdateEntryFields`**

Substituir o bloco atual por:

```dart
class UpdateEntryFields {
  final String descricao;
  final double valor;
  final String categoria;
  final String rateio;
  final String parcela;
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

- [ ] **Step 2: Verificar que o analyzer aponta para o call site quebrado**

Run: `cd app && flutter analyze lib/features/lancamento/edit_dialog.dart`
Expected: erro em `edit_dialog.dart:85` indicando que `data`, `dataRef`, `origem` são obrigatórios.

Isso é esperado — o call site é corrigido no Task 5. Não commitar ainda.

- [ ] **Step 3: NÃO COMMITAR isoladamente** — esse change quebra o build sozinho. Mantenha no working tree pro Task 5.

---

## Task 3: Date helpers (TDD)

**Files:**
- Modify: `app/lib/core/format/dates.dart`
- Modify: `app/test/core/format/dates_test.dart`

- [ ] **Step 1: Escrever os testes (devem falhar)**

Adicionar no final de `app/test/core/format/dates_test.dart`, antes do fechamento do `void main`:

```dart
  group('parseBrDateTime', () {
    test('parseia DD/MM/YYYY HH:MM', () {
      final d = parseBrDateTime('11/05/2026 14:32');
      expect(d.year, 2026);
      expect(d.month, 5);
      expect(d.day, 11);
      expect(d.hour, 14);
      expect(d.minute, 32);
    });

    test('retorna epoch zero para formato inválido', () {
      expect(parseBrDateTime(''), DateTime.fromMillisecondsSinceEpoch(0));
      expect(parseBrDateTime('11/05/2026'),
          DateTime.fromMillisecondsSinceEpoch(0));
      expect(parseBrDateTime('2026-05-11T14:32'),
          DateTime.fromMillisecondsSinceEpoch(0));
    });
  });

  group('formatBrDate', () {
    test('formata DateTime para DD/MM/YYYY', () {
      expect(formatBrDate(DateTime(2026, 5, 11)), '11/05/2026');
      expect(formatBrDate(DateTime(2026, 1, 9)), '09/01/2026');
      expect(formatBrDate(DateTime(2026, 12, 31)), '31/12/2026');
    });
  });

  group('formatBrDateTime', () {
    test('formata DateTime para DD/MM/YYYY HH:MM', () {
      expect(formatBrDateTime(DateTime(2026, 5, 11, 14, 32)),
          '11/05/2026 14:32');
      expect(formatBrDateTime(DateTime(2026, 1, 9, 7, 5)),
          '09/01/2026 07:05');
    });
  });

  group('relativeTime', () {
    test('< 1 min => agora', () {
      final now = DateTime.now();
      expect(relativeTime(now.subtract(const Duration(seconds: 20))), 'agora');
    });

    test('minutos', () {
      final now = DateTime.now();
      expect(relativeTime(now.subtract(const Duration(minutes: 5))), 'há 5 min');
    });

    test('horas', () {
      final now = DateTime.now();
      expect(relativeTime(now.subtract(const Duration(hours: 3))), 'há 3h');
    });

    test('dias', () {
      final now = DateTime.now();
      expect(relativeTime(now.subtract(const Duration(days: 2))), 'há 2d');
    });
  });
```

- [ ] **Step 2: Rodar os testes (devem falhar)**

Run: `cd app && flutter test test/core/format/dates_test.dart`
Expected: 4 grupos novos falham com "The function 'parseBrDateTime' isn't defined" etc.

- [ ] **Step 3: Implementar os helpers em `app/lib/core/format/dates.dart`**

Adicionar no final do arquivo (após `mmYYYY`):

```dart
/// "DD/MM/YYYY HH:MM" -> DateTime. Inválido -> DateTime(1970).
DateTime parseBrDateTime(String s) {
  final parts = s.split(' ');
  if (parts.length != 2) return DateTime.fromMillisecondsSinceEpoch(0);
  final dateParts = parts[0].split('/');
  final timeParts = parts[1].split(':');
  if (dateParts.length != 3 || timeParts.length != 2) {
    return DateTime.fromMillisecondsSinceEpoch(0);
  }
  final d = int.tryParse(dateParts[0]);
  final m = int.tryParse(dateParts[1]);
  final y = int.tryParse(dateParts[2]);
  final hh = int.tryParse(timeParts[0]);
  final mm = int.tryParse(timeParts[1]);
  if (d == null || m == null || y == null || hh == null || mm == null) {
    return DateTime.fromMillisecondsSinceEpoch(0);
  }
  return DateTime(y, m, d, hh, mm);
}

String _pad2(int n) => n < 10 ? '0$n' : '$n';

/// DateTime -> "DD/MM/YYYY".
String formatBrDate(DateTime d) =>
    '${_pad2(d.day)}/${_pad2(d.month)}/${d.year}';

/// DateTime -> "DD/MM/YYYY HH:MM".
String formatBrDateTime(DateTime d) =>
    '${formatBrDate(d)} ${_pad2(d.hour)}:${_pad2(d.minute)}';

/// DateTime -> "agora" / "há N min" / "há Nh" / "há Nd" (pt-BR).
String relativeTime(DateTime when) {
  final diff = DateTime.now().difference(when);
  if (diff.inMinutes < 1) return 'agora';
  if (diff.inMinutes < 60) return 'há ${diff.inMinutes} min';
  if (diff.inHours < 24) return 'há ${diff.inHours}h';
  return 'há ${diff.inDays}d';
}
```

- [ ] **Step 4: Rodar os testes (devem passar)**

Run: `cd app && flutter test test/core/format/dates_test.dart`
Expected: All tests pass.

- [ ] **Step 5: Commit**

```bash
git add app/lib/core/format/dates.dart app/test/core/format/dates_test.dart
git commit -m "feat(app): helpers parseBrDateTime/formatBrDate/relativeTime"
```

---

## Task 4: Locale pt-BR no MaterialApp

**Files:**
- Modify: `app/pubspec.yaml`
- Modify: `app/lib/app.dart`

- [ ] **Step 1: Adicionar `flutter_localizations` no pubspec**

Em `app/pubspec.yaml`, na seção `dependencies:`, adicionar logo após `flutter_web_plugins`:

```yaml
  flutter_localizations:
    sdk: flutter
```

- [ ] **Step 2: Rodar `flutter pub get`**

Run: `cd app && flutter pub get`
Expected: "Got dependencies!" sem warnings novos.

- [ ] **Step 3: Configurar locale em `app.dart`**

No topo de `app/lib/app.dart`, adicionar imports:

```dart
import 'package:flutter_localizations/flutter_localizations.dart';
```

Substituir o `MaterialApp.router` no `build`:

```dart
@override
Widget build(BuildContext context) {
  return MaterialApp.router(
    title: 'hook-finance',
    theme: buildAppTheme(),
    routerConfig: _router,
    debugShowCheckedModeBanner: false,
    locale: const Locale('pt', 'BR'),
    supportedLocales: const [Locale('pt', 'BR'), Locale('en')],
    localizationsDelegates: const [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
  );
}
```

- [ ] **Step 4: Build sanity check**

Run: `cd app && flutter analyze lib/app.dart`
Expected: No issues found.

- [ ] **Step 5: Commit**

```bash
git add app/pubspec.yaml app/pubspec.lock app/lib/app.dart
git commit -m "feat(app): habilita locale pt-BR no MaterialApp"
```

---

## Task 5: Modal de edição com campos editáveis novos

**Files:**
- Modify: `app/lib/features/lancamento/edit_dialog.dart` (rewrite)

- [ ] **Step 1: Rescrever `edit_dialog.dart`**

Conteúdo completo (substitui o arquivo inteiro):

```dart
// Spec: docs/specs/pages/lancamento.md (modal de edição)
// Spec: docs/specs/rules/parcela-format.md (math do total)

import 'package:flutter/material.dart';
import '../../api/endpoints.dart';
import '../../core/format/dates.dart';
import '../../core/format/money.dart';
import '../../core/rules/parcela.dart';
import '../../core/types.dart';

const List<String> _origemOptions = [
  'Cartão',
  'Pix (contas)',
  'Pessoal',
  'Empregados',
  'Contas',
];

class EditDialog extends StatefulWidget {
  final Entry entry;
  final List<ExpenseRow> rowsForCategoriaSuggestions;
  final ApiEndpoints api;

  const EditDialog({
    super.key,
    required this.entry,
    required this.rowsForCategoriaSuggestions,
    required this.api,
  });

  @override
  State<EditDialog> createState() => _EditDialogState();
}

class _EditDialogState extends State<EditDialog> {
  late final TextEditingController _descricaoCtrl;
  late final TextEditingController _valorCtrl;
  late final TextEditingController _categoriaCtrl;
  late String _rateio;
  late int _parcela;
  late double _originalTotal;
  late DateTime _data;
  late DateTime _dataRef;
  late String _origem;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final e = widget.entry;
    final initialTotal = parcelaTotal(e.parcela);
    _originalTotal = (e.valor) * initialTotal;
    _descricaoCtrl = TextEditingController(text: e.descricao);
    _valorCtrl = TextEditingController(
      text: e.valor.toStringAsFixed(2).replaceAll('.', ','),
    );
    _categoriaCtrl = TextEditingController(text: e.categoria);
    _rateio = e.rateio;
    _parcela = initialTotal;
    _data = parseBrDate(e.data);
    _dataRef = parseBrDateTime(e.dataRef);
    _origem = e.origem;
  }

  @override
  void dispose() {
    _descricaoCtrl.dispose();
    _valorCtrl.dispose();
    _categoriaCtrl.dispose();
    super.dispose();
  }

  double _readValor() {
    final raw = _valorCtrl.text.trim().replaceAll('.', '').replaceAll(',', '.');
    return double.tryParse(raw) ?? 0;
  }

  void _adjustParcela(int delta) {
    final next = (_parcela + delta).clamp(1, 99);
    if (next == _parcela) return;
    setState(() {
      _parcela = next;
      final novoValor = _originalTotal / _parcela;
      _valorCtrl.text = novoValor.toStringAsFixed(2).replaceAll('.', ',');
    });
  }

  void _onValorChanged(String _) {
    _originalTotal = _readValor() * _parcela;
    setState(() {});
  }

  Future<void> _pickData() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _data.year < 2000 ? DateTime.now() : _data,
      firstDate: DateTime(2020, 1, 1),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null && mounted) {
      setState(() => _data = picked);
    }
  }

  Future<void> _pickDataRefDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dataRef.year < 2000 ? DateTime.now() : _dataRef,
      firstDate: DateTime(2020, 1, 1),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null && mounted) {
      setState(() {
        _dataRef = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _dataRef.hour,
          _dataRef.minute,
        );
      });
    }
  }

  Future<void> _pickDataRefTime() async {
    final initial = _dataRef.year < 2000
        ? TimeOfDay.now()
        : TimeOfDay(hour: _dataRef.hour, minute: _dataRef.minute);
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
    );
    if (picked != null && mounted) {
      setState(() {
        _dataRef = DateTime(
          _dataRef.year,
          _dataRef.month,
          _dataRef.day,
          picked.hour,
          picked.minute,
        );
      });
    }
  }

  Future<void> _save() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final fields = UpdateEntryFields(
        descricao: _descricaoCtrl.text.trim(),
        valor: _readValor(),
        categoria: _categoriaCtrl.text.trim(),
        rateio: _rateio,
        parcela: _parcela > 1 ? '1/$_parcela' : '',
        data: formatBrDate(_data),
        dataRef: formatBrDateTime(_dataRef),
        origem: _origem,
      );
      final r = await widget.api.updateEntry(widget.entry.row, fields);
      if (!mounted) return;
      if (r.ok) {
        Navigator.of(context).pop(true);
      } else {
        setState(() => _error = r.error ?? 'Erro');
      }
    } catch (err) {
      if (mounted) setState(() => _error = err.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Excluir lançamento?'),
        content: const Text('Esta ação não pode ser desfeita.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final r = await widget.api.deleteEntry(widget.entry.row);
      if (!mounted) return;
      if (r.ok) {
        Navigator.of(context).pop(true);
      } else {
        setState(() => _error = r.error ?? 'Erro');
      }
    } catch (err) {
      if (mounted) setState(() => _error = err.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categorias = <String>{
      for (final r in widget.rowsForCategoriaSuggestions)
        if (r.categoria.isNotEmpty) r.categoria,
    }.toList()
      ..sort();

    // Se a origem cru da planilha não está no enum (legado), incluir como item
    // extra com prefixo "(?)" para o usuário corrigir sem perder o valor.
    final origemItems = <String>[..._origemOptions];
    if (_origem.isNotEmpty && !origemItems.contains(_origem)) {
      origemItems.add(_origem);
    }

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Editar lançamento',
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    color: theme.colorScheme.error,
                    tooltip: 'Excluir lançamento',
                    onPressed: _busy ? null : _delete,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _PickerField(
                label: 'Mês Fatura',
                value: _data.year < 2000
                    ? '— (toque para escolher)'
                    : monthYearShort(formatBrDate(_data)),
                onTap: _busy ? null : _pickData,
              ),
              const SizedBox(height: 12),
              _DataRefField(
                value: _dataRef,
                onPickDate: _busy ? null : _pickDataRefDate,
                onPickTime: _busy ? null : _pickDataRefTime,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue:
                    origemItems.contains(_origem) ? _origem : null,
                decoration: const InputDecoration(labelText: 'Origem'),
                items: [
                  for (final o in origemItems)
                    DropdownMenuItem(
                      value: o,
                      child: Text(
                        _origemOptions.contains(o) ? o : '(?) $o',
                      ),
                    ),
                ],
                onChanged: _busy
                    ? null
                    : (v) => setState(() => _origem = v ?? ''),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _descricaoCtrl,
                decoration: const InputDecoration(labelText: 'Descrição'),
                autocorrect: false,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _valorCtrl,
                decoration: const InputDecoration(labelText: 'Valor (R\$)'),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                onChanged: _onValorChanged,
              ),
              const SizedBox(height: 12),
              _CategoriaField(
                controller: _categoriaCtrl,
                options: categorias,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _rateio,
                decoration: const InputDecoration(labelText: 'Rateio'),
                items: const [
                  DropdownMenuItem(value: '', child: Text('(vazio)')),
                  DropdownMenuItem(value: 'Julio', child: Text('Julio')),
                  DropdownMenuItem(value: 'Dani', child: Text('Dani')),
                  DropdownMenuItem(
                      value: 'Metade', child: Text('Metade (compartilhado)')),
                  DropdownMenuItem(value: 'Alzira', child: Text('Alzira')),
                ],
                onChanged: (v) => setState(() => _rateio = v ?? ''),
              ),
              const SizedBox(height: 12),
              _ParcelaField(
                parcela: _parcela,
                originalTotal: _originalTotal,
                onMinus: () => _adjustParcela(-1),
                onPlus: () => _adjustParcela(1),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  'Erro: $_error',
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  OutlinedButton(
                    onPressed: _busy
                        ? null
                        : () => Navigator.of(context).pop(false),
                    child: const Text('Cancelar'),
                  ),
                  const Spacer(),
                  FilledButton(
                    onPressed: _busy ? null : _save,
                    child: Text(_busy ? 'Salvando...' : 'Salvar'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoriaField extends StatelessWidget {
  final TextEditingController controller;
  final List<String> options;

  const _CategoriaField({required this.controller, required this.options});

  @override
  Widget build(BuildContext context) {
    return Autocomplete<String>(
      initialValue: TextEditingValue(text: controller.text),
      optionsBuilder: (textValue) {
        if (textValue.text.isEmpty) return options;
        final q = textValue.text.toLowerCase();
        return options.where((o) => o.toLowerCase().contains(q));
      },
      onSelected: (v) => controller.text = v,
      fieldViewBuilder:
          (context, fieldController, focusNode, onFieldSubmitted) {
        fieldController.text = controller.text;
        fieldController.addListener(() {
          if (controller.text != fieldController.text) {
            controller.text = fieldController.text;
          }
        });
        return TextField(
          controller: fieldController,
          focusNode: focusNode,
          decoration: const InputDecoration(labelText: 'Categoria'),
          autocorrect: false,
        );
      },
    );
  }
}

class _ParcelaField extends StatelessWidget {
  final int parcela;
  final double originalTotal;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  const _ParcelaField({
    required this.parcela,
    required this.originalTotal,
    required this.onMinus,
    required this.onPlus,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Parcela',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            FilledButton(
              onPressed: onMinus,
              style: FilledButton.styleFrom(
                shape: const CircleBorder(),
                padding: const EdgeInsets.all(12),
              ),
              child: const Text('−', style: TextStyle(fontSize: 18)),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 56,
              child: Text(
                '${parcela}x',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontFeatures: const [FontFeature.tabularFigures()],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: onPlus,
              style: FilledButton.styleFrom(
                shape: const CircleBorder(),
                padding: const EdgeInsets.all(12),
              ),
              child: const Text('+', style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: 'Total da compra: ',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              TextSpan(
                text: 'R\$ ${formatMoney(originalTotal)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PickerField extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback? onTap;

  const _PickerField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: double.infinity,
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF0ECE2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: theme.colorScheme.outlineVariant),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(value, style: theme.textTheme.bodyMedium),
                ),
                const Icon(Icons.calendar_today_outlined, size: 18),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _DataRefField extends StatelessWidget {
  final DateTime value;
  final VoidCallback? onPickDate;
  final VoidCallback? onPickTime;

  const _DataRefField({
    required this.value,
    required this.onPickDate,
    required this.onPickTime,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isInvalid = value.year < 2000;
    final dateLabel = isInvalid ? '—' : formatBrDate(value);
    final timeLabel = isInvalid
        ? '--:--'
        : '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';

    Widget chip({
      required IconData icon,
      required String label,
      required VoidCallback? onTap,
    }) {
      return Expanded(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF0ECE2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: theme.colorScheme.outlineVariant),
            ),
            child: Row(
              children: [
                Icon(icon, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(label, style: theme.textTheme.bodyMedium),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Data Referência',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            chip(
              icon: Icons.calendar_today_outlined,
              label: dateLabel,
              onTap: onPickDate,
            ),
            const SizedBox(width: 8),
            chip(
              icon: Icons.access_time,
              label: timeLabel,
              onTap: onPickTime,
            ),
          ],
        ),
      ],
    );
  }
}
```

- [ ] **Step 2: Análise estática**

Run: `cd app && flutter analyze lib/features/lancamento/edit_dialog.dart lib/core/types.dart`
Expected: No issues found.

- [ ] **Step 3: Build + smoke test manual**

Run: `cd app && flutter run -d chrome` (ou `-d <android-device>` se preferir).
Smoke test:
- Abrir Lançamentos → tap em qualquer item → modal abre.
- Verificar 3 novos campos: Mês Fatura, Data Referência, Origem.
- Tap em Mês Fatura → DatePicker abre em pt-BR. Escolher data diferente. Display atualiza pra "maio de 2026".
- Tap em chip de data em Data Referência → DatePicker. Tap em chip de hora → TimePicker.
- Mudar Origem no dropdown.
- Salvar. Snackbar de sucesso (ou erro com mensagem). Reabrir o item — valores persistem.

- [ ] **Step 4: Commit**

```bash
git add app/lib/core/types.dart app/lib/features/lancamento/edit_dialog.dart
git commit -m "feat(app): edita data/dataRef/origem no modal de lançamento"
```

---

## Task 6: Pull-to-refresh em Lançamentos

**Files:**
- Modify: `app/lib/features/lancamento/lancamento_page.dart`

- [ ] **Step 1: Adicionar import e estado de refresh**

No topo de `app/lib/features/lancamento/lancamento_page.dart`, garantir os imports (alguns já existem):

```dart
import '../../state/data_providers.dart'; // já presente
```

Adicionar campo de estado e handler em `_LancamentoPageState` (logo após `_Tab _tab = _Tab.edit;`):

```dart
  bool _refreshing = false;

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
    } catch (e) {
      error = '$e';
    }
    if (!mounted) return;
    setState(() => _refreshing = false);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
            error == null ? 'Atualizado' : 'Falha ao atualizar: $error'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        backgroundColor:
            error == null ? BloomColors.ink : BloomColors.bad,
      ),
    );
  }
```

- [ ] **Step 2: Envolver o build em `RefreshIndicator`**

Substituir o `build` de `_LancamentoPageState`:

```dart
  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: BloomColors.violet,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.only(
          bottom: 70 + MediaQuery.of(context).padding.bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const ScreenHeader(title: 'Últimos lançamentos'),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: _TabSwitcher(
                tab: _tab,
                onChange: (t) => setState(() => _tab = t),
              ),
            ),
            const SizedBox(height: 14),
            if (_tab == _Tab.edit)
              const _EditList()
            else
              _NovoForm(onCancel: () => setState(() => _tab = _Tab.edit)),
          ],
        ),
      ),
    );
  }
```

- [ ] **Step 3: Análise + smoke test**

Run: `cd app && flutter analyze lib/features/lancamento/lancamento_page.dart`
Expected: No issues found.

Smoke test no APK ou chrome: na aba Lançamentos, arrastar pra baixo no topo da lista → spinner aparece → dados recarregam → snackbar "Atualizado".

- [ ] **Step 4: Commit**

```bash
git add app/lib/features/lancamento/lancamento_page.dart
git commit -m "feat(app): pull-to-refresh em Lançamentos"
```

---

## Task 7: Dependência `path_provider`

**Files:**
- Modify: `app/pubspec.yaml`

- [ ] **Step 1: Adicionar a dep**

Em `app/pubspec.yaml`, na seção `dependencies:`, abaixo de `installed_apps`:

```yaml
  path_provider: ^2.1.4
```

- [ ] **Step 2: `flutter pub get`**

Run: `cd app && flutter pub get`
Expected: "Got dependencies!". Se a versão resolver pra algo diferente (ex.: 2.1.5), aceitar.

- [ ] **Step 3: Commit**

```bash
git add app/pubspec.yaml app/pubspec.lock
git commit -m "chore(app): adiciona path_provider"
```

---

## Task 8: `CaptureLogEntry` model (TDD)

**Files:**
- Create: `app/lib/state/capture_log_entry.dart`
- Create: `app/test/state/capture_log_entry_test.dart`

- [ ] **Step 1: Escrever os testes (falham)**

Criar `app/test/state/capture_log_entry_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:hook_finance/state/capture_log_entry.dart';

void main() {
  group('CaptureLogEntry.toJson', () {
    test('serializa todos os campos', () {
      const e = CaptureLogEntry(
        ts: 1715441234567,
        package: 'com.nu.production',
        title: 'Compra aprovada',
        content: 'R\$ 42,50 em MERCADO',
        status: 'ok',
        error: null,
      );
      expect(e.toJson(), {
        'ts': 1715441234567,
        'package': 'com.nu.production',
        'title': 'Compra aprovada',
        'content': 'R\$ 42,50 em MERCADO',
        'status': 'ok',
        'error': null,
      });
    });

    test('inclui error quando presente', () {
      const e = CaptureLogEntry(
        ts: 1,
        package: 'p',
        title: 't',
        content: 'c',
        status: 'error',
        error: 'Backend: 500',
      );
      expect(e.toJson()['error'], 'Backend: 500');
    });
  });

  group('CaptureLogEntry.fromJson', () {
    test('parseia JSON completo', () {
      final e = CaptureLogEntry.fromJson({
        'ts': 1715441234567,
        'package': 'com.nu.production',
        'title': 'Compra aprovada',
        'content': 'corpo',
        'status': 'ok',
        'error': null,
      });
      expect(e.ts, 1715441234567);
      expect(e.package, 'com.nu.production');
      expect(e.title, 'Compra aprovada');
      expect(e.content, 'corpo');
      expect(e.status, 'ok');
      expect(e.error, null);
    });

    test('defaults para campos ausentes', () {
      final e = CaptureLogEntry.fromJson(<String, dynamic>{});
      expect(e.ts, 0);
      expect(e.package, '');
      expect(e.title, '');
      expect(e.content, '');
      expect(e.status, 'ok');
      expect(e.error, null);
    });
  });

  group('CaptureLogEntry.when', () {
    test('converte ts para DateTime', () {
      const e = CaptureLogEntry(
        ts: 1715441234567,
        package: 'p',
        title: 't',
        content: 'c',
        status: 'ok',
      );
      expect(e.when, DateTime.fromMillisecondsSinceEpoch(1715441234567));
    });
  });
}
```

- [ ] **Step 2: Rodar (devem falhar)**

Run: `cd app && flutter test test/state/capture_log_entry_test.dart`
Expected: FAIL "package:hook_finance/state/capture_log_entry.dart not found".

- [ ] **Step 3: Implementar o model**

Criar `app/lib/state/capture_log_entry.dart`:

```dart
// Spec: docs/specs/features/captura-notificacoes.md (Histórico de capturas)

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

- [ ] **Step 4: Rodar (passam)**

Run: `cd app && flutter test test/state/capture_log_entry_test.dart`
Expected: All tests pass.

- [ ] **Step 5: Commit**

```bash
git add app/lib/state/capture_log_entry.dart app/test/state/capture_log_entry_test.dart
git commit -m "feat(app): model CaptureLogEntry"
```

---

## Task 9: `CaptureHistoryProvider`

**Files:**
- Create: `app/lib/state/capture_history_provider.dart`

- [ ] **Step 1: Implementar o provider**

Criar `app/lib/state/capture_history_provider.dart`:

```dart
// Spec: docs/specs/features/captura-notificacoes.md (Histórico de capturas)
//
// Provider que mantém em memória + persiste em
// `<app_documents_dir>/capture_history.json` as últimas 50 capturas
// de notificação. Web é no-op (path_provider não suporta).

import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import 'capture_log_entry.dart';

const int _maxEntries = 50;
const String _fileName = 'capture_history.json';

class CaptureHistoryNotifier
    extends AsyncNotifier<List<CaptureLogEntry>> {
  File? _cachedFile;

  Future<File?> _file() async {
    if (kIsWeb) return null;
    if (_cachedFile != null) return _cachedFile;
    final dir = await getApplicationDocumentsDirectory();
    _cachedFile = File('${dir.path}/$_fileName');
    return _cachedFile;
  }

  @override
  Future<List<CaptureLogEntry>> build() async {
    final f = await _file();
    if (f == null || !await f.exists()) return const [];
    try {
      final raw = await f.readAsString();
      final list = jsonDecode(raw) as List;
      return list
          .map((e) => CaptureLogEntry.fromJson(e as Map<String, dynamic>))
          .toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  Future<void> append(CaptureLogEntry entry) async {
    final current = state.valueOrNull ?? const <CaptureLogEntry>[];
    final next = <CaptureLogEntry>[entry, ...current];
    final trimmed = next.length > _maxEntries
        ? next.sublist(0, _maxEntries)
        : next;
    state = AsyncValue.data(trimmed);
    final f = await _file();
    if (f == null) return;
    try {
      await f.writeAsString(
        jsonEncode(trimmed.map((e) => e.toJson()).toList()),
        flush: true,
      );
    } catch (_) {
      // Best-effort persist: estado em memória já foi atualizado.
    }
  }

  Future<void> clear() async {
    state = const AsyncValue.data([]);
    final f = await _file();
    if (f == null) return;
    try {
      if (await f.exists()) await f.delete();
    } catch (_) {
      // ignora
    }
  }
}

final captureHistoryProvider = AsyncNotifierProvider<
    CaptureHistoryNotifier, List<CaptureLogEntry>>(
  CaptureHistoryNotifier.new,
);
```

- [ ] **Step 2: Análise estática**

Run: `cd app && flutter analyze lib/state/capture_history_provider.dart`
Expected: No issues found.

- [ ] **Step 3: Commit**

```bash
git add app/lib/state/capture_history_provider.dart
git commit -m "feat(app): provider de histórico de capturas (até 50, JSON file)"
```

---

## Task 10: `_handleEvent` grava no histórico

**Files:**
- Modify: `app/lib/state/notification_capture_provider.dart`

- [ ] **Step 1: Adicionar imports**

No topo de `app/lib/state/notification_capture_provider.dart`, adicionar:

```dart
import 'capture_history_provider.dart';
import 'capture_log_entry.dart';
```

- [ ] **Step 2: Adaptar `_handleEvent` pra registrar a captura**

Substituir a função `_handleEvent` no final do arquivo por:

```dart
Future<void> _handleEvent(Ref ref, ServiceNotificationEvent event) async {
  final notifier = ref.read(notificationCaptureProvider.notifier);
  final history = ref.read(captureHistoryProvider.notifier);
  final config = ref.read(notificationCaptureProvider);

  if (event.hasRemoved == true) return;
  if (event.packageName != config.packageName) return;

  final title = event.title ?? '';
  final content = event.content ?? '';
  if (config.titleRegex.isNotEmpty) {
    try {
      if (!RegExp(config.titleRegex).hasMatch(title)) return;
    } catch (_) {
      // Regex inválida: trata como "sem filtro" e segue.
    }
  }
  if (title.isEmpty && content.isEmpty) return;

  final ts = DateTime.now().millisecondsSinceEpoch;
  final client = ref.read(apiClientProvider);

  Future<void> log(String status, String? error) {
    return history.append(CaptureLogEntry(
      ts: ts,
      package: event.packageName ?? '',
      title: title,
      content: content,
      status: status,
      error: error,
    ));
  }

  try {
    final r = await client.post('webhookFromApp', {
      'title': title,
      'text': content,
    });
    if (r['ok'] == true) {
      await notifier.markCapture(
          title: title.isEmpty ? '(sem título)' : title);
      await log('ok', null);
    } else {
      final err = 'Backend: ${r['error'] ?? 'erro'}';
      notifier.setError(err);
      await log('error', err);
    }
  } catch (err) {
    final s = '$err';
    notifier.setError(s);
    await log('error', s);
  }
}
```

- [ ] **Step 3: Análise estática**

Run: `cd app && flutter analyze lib/state/notification_capture_provider.dart`
Expected: No issues found.

- [ ] **Step 4: Commit**

```bash
git add app/lib/state/notification_capture_provider.dart
git commit -m "feat(app): grava captura no histórico após POST"
```

---

## Task 11: Tela `CapturesHistoryPage`

**Files:**
- Create: `app/lib/features/settings/captures_history_page.dart`

- [ ] **Step 1: Criar a tela**

Criar `app/lib/features/settings/captures_history_page.dart`:

```dart
// Spec: docs/specs/features/captura-notificacoes.md (Histórico de capturas)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format/dates.dart';
import '../../state/capture_history_provider.dart';
import '../../state/capture_log_entry.dart';
import '../../theme/bloom_colors.dart';
import '../../theme/bloom_typography.dart';
import '../../widgets/bloom/bloom_card.dart';
import '../../widgets/bloom/bloom_screen.dart';
import '../../widgets/bloom/screen_header.dart';

class CapturesHistoryPage extends ConsumerWidget {
  const CapturesHistoryPage({super.key});

  Future<void> _confirmClear(
      BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Limpar histórico?'),
        content: const Text(
            'Remove todas as capturas registradas. Não afeta a planilha.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Limpar'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(captureHistoryProvider.notifier).clear();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(captureHistoryProvider);
    final entries = async.valueOrNull ?? const <CaptureLogEntry>[];
    final loading = async.isLoading && !async.hasValue;

    return BloomScreen(
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          bottom: 24 + MediaQuery.of(context).padding.bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ScreenHeader(
              title: 'Histórico de capturas',
              showBack: true,
              trailing: entries.isEmpty
                  ? null
                  : IconButton(
                      onPressed: () => _confirmClear(context, ref),
                      icon: const Icon(Icons.delete_sweep_outlined),
                      tooltip: 'Limpar histórico',
                      color: BloomColors.inkSoft,
                    ),
            ),
            const SizedBox(height: 12),
            if (loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 60),
                child: Center(
                  child: CircularProgressIndicator(
                      color: BloomColors.violet),
                ),
              )
            else if (entries.isEmpty)
              const _EmptyState()
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: Column(
                  children: [
                    for (final e in entries) ...[
                      _CaptureCard(entry: e),
                      const SizedBox(height: 8),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 40),
      child: BloomCard(
        padding: const EdgeInsets.all(22),
        child: Column(
          children: [
            const Icon(Icons.history_outlined,
                size: 36, color: BloomColors.muted),
            const SizedBox(height: 10),
            Text(
              'Nenhuma captura ainda. Ative no card acima e aguarde uma notificação.',
              textAlign: TextAlign.center,
              style: BloomTypography.geist(
                fontSize: 12.5,
                color: BloomColors.muted,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CaptureCard extends StatelessWidget {
  final CaptureLogEntry entry;
  const _CaptureCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final isOk = entry.status == 'ok';
    return BloomCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      borderRadius: BorderRadius.circular(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isOk ? Icons.check_circle : Icons.error_outline,
                size: 18,
                color: isOk ? BloomColors.good : BloomColors.bad,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  entry.title.isEmpty ? '(sem título)' : entry.title,
                  style: BloomTypography.geist(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: BloomColors.ink,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                relativeTime(entry.when),
                style: BloomTypography.geist(
                  fontSize: 11,
                  color: BloomColors.muted,
                ),
              ),
            ],
          ),
          if (entry.content.isNotEmpty) ...[
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(left: 26),
              child: Text(
                entry.content,
                style: BloomTypography.geist(
                  fontSize: 12,
                  color: BloomColors.muted,
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
          if (!isOk && entry.error != null) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 26),
              child: Text(
                entry.error!,
                style: BloomTypography.geist(
                  fontSize: 11.5,
                  color: BloomColors.bad,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Análise estática**

Run: `cd app && flutter analyze lib/features/settings/captures_history_page.dart`
Expected: No issues found.

- [ ] **Step 3: Commit**

```bash
git add app/lib/features/settings/captures_history_page.dart
git commit -m "feat(app): tela de histórico de capturas"
```

---

## Task 12: Rota + entry-point na Settings + extrair `relativeTime`

**Files:**
- Modify: `app/lib/app.dart`
- Modify: `app/lib/features/settings/settings_page.dart`

- [ ] **Step 1: Adicionar rota em `app.dart`**

No topo, importar:

```dart
import 'features/settings/captures_history_page.dart';
```

Dentro do `GoRouter`, adicionar como filha de `/` (depois da rota `settings`):

```dart
GoRoute(
  path: 'settings/captures',
  builder: (_, _) => const CapturesHistoryPage(),
),
```

- [ ] **Step 2: Trocar `_formatRelative` por `relativeTime` em `settings_page.dart`**

No topo de `app/lib/features/settings/settings_page.dart`, adicionar:

```dart
import '../../core/format/dates.dart';
import 'package:go_router/go_router.dart';
```

Remover a função `_formatRelative` inline e seu call site, substituindo:

```dart
'Última captura: ${_formatRelative(state.lastCaptureAt!)}',
```

por:

```dart
'Última captura: ${relativeTime(state.lastCaptureAt!)}',
```

E remover o método `String _formatRelative(DateTime when) { ... }` no final de `_StatusCard`.

- [ ] **Step 3: Adicionar botão "Ver histórico" no `_StatusCard`**

Em `_StatusCard.build`, dentro da `Column` (após o bloco `if (state.lastError != null)`), antes do fechamento `],`, adicionar:

```dart
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () =>
                  GoRouter.of(context).go('/settings/captures'),
              icon: const Icon(Icons.list_alt, size: 18),
              label: const Text('Ver histórico'),
              style: TextButton.styleFrom(
                  foregroundColor: BloomColors.violet),
            ),
          ),
```

- [ ] **Step 4: Análise estática**

Run: `cd app && flutter analyze lib/app.dart lib/features/settings/settings_page.dart`
Expected: No issues found.

- [ ] **Step 5: Smoke test manual**

`cd app && flutter run -d <device>`:
- Início → engrenagem → Configurações.
- Card STATUS mostra link "Ver histórico" (mesmo sem capturas).
- Tap → navega pra tela vazia "Nenhuma captura ainda."
- (Se Android com captura ativa) disparar uma notificação do app monitorado → voltar → ver entry na lista.
- Tap em "Limpar histórico" → confirma → lista zera.

- [ ] **Step 6: Commit**

```bash
git add app/lib/app.dart app/lib/features/settings/settings_page.dart
git commit -m "feat(app): rota /settings/captures + botão Ver histórico"
```

---

## Task 14: Paginação em Lançamentos ("Carregar mais")

Adicionado depois do pedido inicial do usuário. Lista atual mostra fixo as 10 últimas; queremos um botão no final que carrega mais 10 por tap, até o limite de 100.

**Files:**
- Modify: `app/lib/features/lancamento/lancamento_page.dart`

**Aproveita o backend existente:** `getLastEntries(token, n)` em `Dashboard.gs:218` já aceita qualquer `n` e retorna `min(n, last-1)`. Nada de backend muda. O provider `lastEntriesProvider(n)` (`app/lib/state/data_providers.dart`) é family por `int`, então pedir `lastEntriesProvider(20)`, `lastEntriesProvider(30)`, etc., funciona out-of-the-box (cada `n` é um cache key separado).

### Step 1: Converter `_EditList` em `ConsumerStatefulWidget`

Hoje:
```dart
class _EditList extends ConsumerWidget {
  const _EditList();
  @override
  Widget build(BuildContext context, WidgetRef ref) { ... }
}
```

Trocar por:
```dart
class _EditList extends ConsumerStatefulWidget {
  const _EditList();

  @override
  ConsumerState<_EditList> createState() => _EditListState();
}

class _EditListState extends ConsumerState<_EditList> {
  static const int _step = 10;
  static const int _maxLimit = 100;
  int _limit = _step;

  void _loadMore() {
    setState(() => _limit = (_limit + _step).clamp(_step, _maxLimit));
  }

  @override
  Widget build(BuildContext context) {
    // resto da lógica abaixo
  }
}
```

### Step 2: Reescrever `build` do `_EditListState`

Substituir o corpo de `build` (mantendo o mesmo openEdit + layout, só trocando `10` por `_limit` e adicionando o botão).

```dart
@override
Widget build(BuildContext context) {
  final lastAsync = ref.watch(lastEntriesProvider(_limit));
  final monthAsync = ref.watch(monthDataProvider(null));
  final entries = lastAsync.value?.entries ?? const <Entry>[];
  final loading = lastAsync.isLoading && !lastAsync.hasValue;

  // "Tem mais para carregar" = (a) ainda dá pra subir limite, e (b)
  // o backend devolveu pelo menos `_limit` itens (senão chegamos ao fim).
  final reachedSheetEnd =
      lastAsync.hasValue && entries.length < _limit;
  final atCap = _limit >= _maxLimit;
  final canLoadMore = !loading && !reachedSheetEnd && !atCap;

  Future<void> openEdit(Entry e) async {
    final api = ref.read(apiProvider);
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => EditDialog(
        entry: e,
        rowsForCategoriaSuggestions:
            monthAsync.value?.rows ?? const <ExpenseRow>[],
        api: api,
      ),
    );
    if (saved == true) {
      ref.invalidate(lastEntriesProvider);
      ref.invalidate(monthDataProvider);
    }
  }

  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 22),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                'ÚLTIMOS ${entries.length} · TOQUE PARA EDITAR',
                style: BloomTypography.kicker(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        BloomCard(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          borderRadius: BorderRadius.circular(22),
          child: loading
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: CircularProgressIndicator(
                        color: BloomColors.violet),
                  ),
                )
              : entries.isEmpty
                  ? Padding(
                      padding:
                          const EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text(
                          'Sem lançamentos.',
                          style: BloomTypography.geist(
                            fontSize: 12,
                            color: BloomColors.muted,
                          ),
                        ),
                      ),
                    )
                  : Column(
                      children: [
                        for (var i = 0; i < entries.length; i++)
                          RecentEntryRow(
                            entry: entries[i],
                            showDivider: i > 0,
                            onTap: () => openEdit(entries[i]),
                            highlightMissing: true,
                          ),
                      ],
                    ),
        ),
        const SizedBox(height: 14),
        if (canLoadMore)
          Center(
            child: TextButton.icon(
              onPressed: _loadMore,
              icon: const Icon(Icons.expand_more, size: 18),
              label: Text('Carregar mais ${_remaining()}'),
              style: TextButton.styleFrom(
                foregroundColor: BloomColors.violet,
              ),
            ),
          )
        else if (atCap)
          Center(
            child: Text(
              'Limite de $_maxLimit lançamentos atingido.',
              style: BloomTypography.geist(
                fontSize: 11.5,
                color: BloomColors.muted,
              ),
            ),
          )
        else if (reachedSheetEnd && entries.length > _step)
          Center(
            child: Text(
              'Fim da lista.',
              style: BloomTypography.geist(
                fontSize: 11.5,
                color: BloomColors.muted,
              ),
            ),
          ),
      ],
    ),
  );
}

int _remaining() {
  final remaining = _maxLimit - _limit;
  return remaining < _step ? remaining : _step;
}
```

Notas:
- `_EditListState` está em `ConsumerState`, então `ref` está disponível como propriedade.
- Imports atuais do arquivo já cobrem tudo (`flutter_riverpod`, `BloomColors`, `BloomTypography`, `BloomCard`, `RecentEntryRow`, providers, `Entry`/`ExpenseRow`).
- "Limite atingido" só aparece quando `_limit == 100` (independente de ter chegado no fim do sheet).
- "Fim da lista" aparece quando o backend devolveu menos itens do que `_limit` e estamos além do limite inicial (ou seja, o usuário já carregou mais pelo menos uma vez). Não aparecer no primeiro carregamento quando há poucos lançamentos é uma escolha consciente: nesse caso o vazio já é óbvio pelo número pequeno de itens.

### Step 3: Verify

```
cd app && flutter analyze lib/features/lancamento/lancamento_page.dart
```
Expected: No issues found.

### Step 4: Commit

```bash
git add app/lib/features/lancamento/lancamento_page.dart
git commit -m "feat(app): paginação 10-em-10 (cap 100) em Lançamentos"
```

---

## Task 13: Atualizar docs/specs

**Files:**
- Modify: `docs/specs/pages/lancamento.md`
- Modify: `docs/specs/features/captura-notificacoes.md`
- Modify: `docs/specs/api/endpoints.md`

- [ ] **Step 1: `docs/specs/pages/lancamento.md`**

Atualizar o frontmatter (`last_updated: 2026-05-11`) e na seção "Modal de edição":

- Trocar o subitem **Read-only fields:** por **Editáveis (novos):** com os três campos: `Mês Fatura`, `Data Referência`, `Origem`.
- Reordenar a lista de campos editáveis pra colocar os três novos no topo, antes de Descrição.
- Em "Mês Fatura": dizer que display é `monthYearShort(entry.data)` e tap abre `showDatePicker` que preserva o DD escolhido. Send `data: "DD/MM/YYYY"`.
- Em "Data Referência": dois chips (data + hora) que abrem `showDatePicker`/`showTimePicker`. Send `dataRef: "DD/MM/YYYY HH:MM"`.
- Em "Origem": `DropdownButtonFormField` com `ADD_ENTRY_ORIGEMS` (Cartão, Pix (contas), Pessoal, Empregados, Contas). Origens cruas legadas aparecem como item extra prefixado `(?)`.
- Atualizar a seção "Save" — body agora inclui `data`, `dataRef`, `origem` em `fields`.

- [ ] **Step 2: `docs/specs/features/captura-notificacoes.md`**

Atualizar `last_updated: 2026-05-11` e adicionar nova seção antes de "Implementações":

```markdown
### Histórico de capturas

Persiste as últimas 50 capturas (sucesso ou erro) em `<app_documents_dir>/capture_history.json` via `path_provider`. Eventos descartados nos filtros (regex/package/vazio) NÃO entram.

Schema (array, mais recente em primeiro):
- `ts` (int, ms): `DateTime.now().millisecondsSinceEpoch`
- `package` (string): `event.packageName`
- `title`, `content` (strings)
- `status`: `"ok"` (backend ok ou dedup) | `"error"`
- `error` (string?): mensagem em caso de erro

Provider: `captureHistoryProvider` (`AsyncNotifierProvider<CaptureHistoryNotifier, List<CaptureLogEntry>>`). Métodos: `append`, `clear`. Append faz prepend + trim para 50.

Tela: `/settings/captures` (rota filha de `/`) renderiza lista de cards com ícone status, título, content (2 linhas), erro (se houver), e timestamp relativo. Header com botão "Limpar". Acessada via TextButton "Ver histórico" no card STATUS da Settings.

Web (PWA): provider retorna `[]` e `append`/`clear` são no-op (`path_provider` não suporta `getApplicationDocumentsDirectory()` no web). A feature de captura em si já é Android-only.
```

Adicionar à lista "Implementações":

```markdown
- **Histórico (provider):** [app/lib/state/capture_history_provider.dart](../../../app/lib/state/capture_history_provider.dart)
- **Histórico (model):** [app/lib/state/capture_log_entry.dart](../../../app/lib/state/capture_log_entry.dart)
- **Histórico (UI):** [app/lib/features/settings/captures_history_page.dart](../../../app/lib/features/settings/captures_history_page.dart)
```

- [ ] **Step 3: `docs/specs/api/endpoints.md`**

Encontrar a seção `updateEntry` e atualizar o contrato:

- `fields` agora inclui (todos obrigatórios): `descricao`, `valor`, `categoria`, `rateio`, `parcela`, `data` (`"DD/MM/YYYY"`), `dataRef` (`"DD/MM/YYYY HH:MM"`), `origem` (enum espelhando `addEntry`).
- Erros novos: `missing_data`, `missing_dataRef`, `missing_origem`, `invalid_origem`.

- [ ] **Step 4: Commit**

```bash
git add docs/specs/pages/lancamento.md docs/specs/features/captura-notificacoes.md docs/specs/api/endpoints.md
git commit -m "docs(spec): atualiza specs com edição expandida + histórico de capturas"
```

---

## Verificação final

- [ ] **Run** `cd app && flutter analyze` — Expected: No issues.
- [ ] **Run** `cd app && flutter test` — Expected: All tests pass (incluindo os novos `dates_test.dart` e `capture_log_entry_test.dart`).
- [ ] **Run** `cd app && flutter build apk --debug` — Expected: APK em `app/build/app/outputs/flutter-apk/app-debug.apk`. Confirma que tudo compila pro Android.
- [ ] **Smoke test** ponta-a-ponta no APK:
  - Modal edita Mês Fatura/Data Ref/Origem; salva; reabre — valores persistem.
  - Pull-to-refresh na aba Lançamentos funciona (snackbar "Atualizado").
  - Captura uma notificação real → ver entrada no `/settings/captures`. Limpar funciona.
