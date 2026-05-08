// Spec: docs/specs/pages/detalhe.md

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants.dart';
import '../../core/format/money.dart';
import '../../core/types.dart';
import '../../state/data_providers.dart';
import '../../widgets/sticky_header.dart';

class DetalhePage extends ConsumerWidget {
  const DetalhePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final currentMonth = ref.watch(currentMonthProvider);
    final monthAsync = ref.watch(monthDataProvider(currentMonth));
    final rows = monthAsync.value?.rows ?? const <ExpenseRow>[];
    final loading = monthAsync.isLoading && !monthAsync.hasValue;

    final byPerson = <String, _PersonGroup>{};
    for (final r in rows) {
      if (r.origem != 'Cartão') continue;
      if (r.rateio.isEmpty || r.rateio == 'Metade') continue;
      final g = byPerson.putIfAbsent(r.rateio, () => _PersonGroup());
      g.total += r.valor;
      g.items.add(r);
    }
    final others = byPerson.keys
        .where((p) => !kPersonOrder.contains(p))
        .toList()
      ..sort();
    final ordered = [...kPersonOrder, ...others]
        .where((p) => byPerson.containsKey(p))
        .toList();

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(monthDataProvider);
        try {
          await ref.read(monthDataProvider(currentMonth).future);
        } catch (_) {}
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const StickyHeader(),
            const SizedBox(height: 12),
          if (loading)
            ...List.generate(
              3,
              (_) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            )
          else if (ordered.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Text(
                  'Sem despesas pessoais neste mês.',
                  style: TextStyle(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            )
          else
            ...ordered.map((p) {
              final group = byPerson[p]!;
              final items = [...group.items]
                ..sort((a, b) => b.dataRef.compareTo(a.dataRef));
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Card(
                  clipBehavior: Clip.antiAlias,
                  child: ExpansionTile(
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(p,
                            style:
                                theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                )),
                        Text(
                          'R\$ ${formatMoney(group.total)}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            for (final it in items)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: 110,
                                      child: Text(
                                        it.dataRef,
                                        style: theme.textTheme.bodySmall,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        it.descricao,
                                        style: theme.textTheme.bodySmall,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Text(
                                      formatMoney(it.valor),
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        fontFeatures: const [
                                          FontFeature.tabularFigures()
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _PersonGroup {
  double total = 0;
  final List<ExpenseRow> items = [];
}
