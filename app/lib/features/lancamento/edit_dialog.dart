// Spec: docs/specs/pages/lancamento.md (modal de edição)
// Spec: docs/specs/rules/parcela-format.md (math do total)

import 'package:flutter/material.dart';
import '../../api/endpoints.dart';
import '../../core/format/money.dart';
import '../../core/rules/parcela.dart';
import '../../core/types.dart';

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
                    icon: const Icon(Icons.close),
                    onPressed: _busy
                        ? null
                        : () => Navigator.of(context).pop(false),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _ReadOnlyField(
                  label: 'Data de referência',
                  value: widget.entry.dataRef.isEmpty ? '—' : widget.entry.dataRef),
              const SizedBox(height: 12),
              _ReadOnlyField(
                  label: 'Origem',
                  value: widget.entry.origem.isEmpty ? '—' : widget.entry.origem),
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
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.colorScheme.error,
                    ),
                    onPressed: _busy ? null : _delete,
                    child: const Text('Excluir'),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: _busy
                        ? null
                        : () => Navigator.of(context).pop(false),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 8),
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
        // Sincroniza nosso controller "real" com o controller do Autocomplete.
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

class _ReadOnlyField extends StatelessWidget {
  final String label;
  final String value;

  const _ReadOnlyField({required this.label, required this.value});

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
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF0ECE2),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: Text(value, style: theme.textTheme.bodyMedium),
        ),
      ],
    );
  }
}
