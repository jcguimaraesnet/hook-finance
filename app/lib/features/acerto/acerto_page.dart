// Spec: docs/specs/pages/acerto.md

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/types.dart';
import '../../state/data_providers.dart';
import '../../theme/breakpoints.dart';
import '../../widgets/acerto_card.dart';
import '../../widgets/sticky_header.dart';

class AcertoPage extends ConsumerWidget {
  const AcertoPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentMonth = ref.watch(currentMonthProvider);
    final monthAsync = ref.watch(monthDataProvider(currentMonth));
    final rows = monthAsync.value?.rows ?? const <ExpenseRow>[];
    final loading = monthAsync.isLoading && !monthAsync.hasValue;
    final isTablet = context.isTabletOrUp;

    final cards = [
      AcertoCard(person: Person.julio, rows: rows, loading: loading),
      AcertoCard(person: Person.dani, rows: rows, loading: loading),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const StickyHeader(),
          const SizedBox(height: 12),
          if (isTablet)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: cards[0]),
                const SizedBox(width: 12),
                Expanded(child: cards[1]),
              ],
            )
          else
            Column(
              children: [
                cards[0],
                const SizedBox(height: 12),
                cards[1],
              ],
            ),
        ],
      ),
    );
  }
}
