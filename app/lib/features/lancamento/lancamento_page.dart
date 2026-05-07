// Spec: docs/specs/pages/lancamento.md

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/format/money.dart';
import '../../core/rules/parcela.dart';
import '../../core/types.dart';
import '../../state/auth_provider.dart';
import '../../state/data_providers.dart';
import '../../widgets/sticky_header.dart';
import 'edit_dialog.dart';

class LancamentoPage extends ConsumerWidget {
  const LancamentoPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final lastAsync = ref.watch(lastEntriesProvider(10));
    final monthAsync = ref.watch(monthDataProvider(null));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const StickyHeader(disabled: true),
          const SizedBox(height: 12),
          if (lastAsync.isLoading && !lastAsync.hasValue)
            ...List.generate(
              3,
              (_) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  height: 64,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            )
          else
            ..._buildEntries(context, ref, lastAsync.value, monthAsync.value),
        ],
      ),
    );
  }

  List<Widget> _buildEntries(
    BuildContext context,
    WidgetRef ref,
    LastEntriesResponse? response,
    MonthDataResponse? monthData,
  ) {
    final entries = response?.entries ?? const <Entry>[];
    if (entries.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 32),
          child: Center(
            child: Text(
              'Sem lançamentos.',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ];
    }
    return [
      for (final e in entries) ...[
        _EntryTile(
          entry: e,
          onTap: () => _openEdit(context, ref, e, monthData?.rows ?? const []),
        ),
        const SizedBox(height: 8),
      ],
    ];
  }

  Future<void> _openEdit(
    BuildContext context,
    WidgetRef ref,
    Entry entry,
    List<ExpenseRow> rowsForCategoria,
  ) async {
    final api = ref.read(apiProvider);
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => EditDialog(
        entry: entry,
        rowsForCategoriaSuggestions: rowsForCategoria,
        api: api,
      ),
    );
    if (saved == true) {
      ref.invalidate(lastEntriesProvider);
      ref.invalidate(monthDataProvider);
    }
  }
}

class _EntryTile extends StatelessWidget {
  final Entry entry;
  final VoidCallback onTap;

  const _EntryTile({required this.entry, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalP = parcelaTotal(entry.parcela);

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${entry.dataRef} · ${entry.origem}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      entry.descricao,
                      style: theme.textTheme.titleSmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'R\$ ${formatMoney(entry.valor)}',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: [
                  if (entry.categoria.isNotEmpty)
                    _Pill(text: entry.categoria),
                  if (entry.rateio.isNotEmpty) _Pill(text: entry.rateio),
                  if (totalP > 1)
                    _Pill(
                      text: entry.parcela,
                      bg: const Color(0xFFF4D35E),
                      fg: const Color(0xFF262626),
                      bold: true,
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

class _Pill extends StatelessWidget {
  final String text;
  final Color? bg;
  final Color? fg;
  final bool bold;

  const _Pill({
    required this.text,
    this.bg,
    this.fg,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg ?? const Color(0xFFF0ECE2),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: theme.textTheme.labelSmall?.copyWith(
          color: fg ?? theme.colorScheme.onSurfaceVariant,
          fontWeight: bold ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    );
  }
}
