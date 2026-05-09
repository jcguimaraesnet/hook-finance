// Spec: docs/specs/pages/inicio.md
// Visão pessoal — donut + buckets + comparativo + recentes.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/format/dates.dart';
import '../../core/format/money.dart';
import '../../core/rules/bucket_deltas.dart';
import '../../core/types.dart';
import '../../state/auth_provider.dart';
import '../../state/data_providers.dart';
import '../../state/nav_provider.dart';
import '../../theme/bloom_colors.dart';
import '../../theme/bloom_typography.dart';
import '../../widgets/bloom/bloom_bottom_nav.dart';
import '../../widgets/bloom/bloom_card.dart';
import '../../widgets/bloom/bloom_donut.dart';
import '../../widgets/bloom/bloom_logo.dart';
import '../../widgets/bloom/month_selector.dart';
import '../../widgets/bloom/person_pill.dart';
import '../../widgets/bloom/recent_entry_row.dart';

class InicioPage extends ConsumerStatefulWidget {
  const InicioPage({super.key});

  @override
  ConsumerState<InicioPage> createState() => _InicioPageState();
}

class _InicioPageState extends ConsumerState<InicioPage> {
  int? _selectedSegment;
  bool _refreshing = false;

  @override
  Widget build(BuildContext context) {
    final person = ref.watch(selectedPersonProvider);
    final currentMonth = ref.watch(currentMonthProvider);
    final monthAsync = ref.watch(monthDataProvider(currentMonth));
    final prevAsync = ref.watch(previousMonthDataProvider);
    final lastAsync = ref.watch(lastEntriesProvider(2));

    final rows = monthAsync.value?.rows ?? const <ExpenseRow>[];
    final prevRows =
        prevAsync.value?.rows ?? const <ExpenseRow>[];

    final juCur = bucketsForPerson(rows, Person.julio);
    final daCur = bucketsForPerson(rows, Person.dani);
    final cur = person == Person.julio ? juCur : daCur;
    final prev = bucketsForPerson(prevRows, person);
    final deltas = bucketDeltas(current: cur, previous: prev);

    final totalCartao = rows
        .where((r) => r.origem == 'Cartão')
        .fold<double>(0, (s, r) => s + r.valor);

    final loading = monthAsync.isLoading && !monthAsync.hasValue;

    Future<void> onRefresh() async {
      if (_refreshing) return;
      setState(() => _refreshing = true);
      final messenger = ScaffoldMessenger.of(context);
      ref.invalidate(monthDataProvider);
      ref.invalidate(previousMonthDataProvider);
      ref.invalidate(historicalSummaryProvider);
      ref.invalidate(lastEntriesProvider);
      String? error;
      try {
        await Future.wait<void>([
          ref.read(monthDataProvider(currentMonth).future),
          ref.read(lastEntriesProvider(2).future),
        ]);
      } catch (e) {
        error = '$e';
      }
      if (!mounted) return;
      setState(() => _refreshing = false);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Text(error == null
              ? 'Atualizado'
              : 'Falha ao atualizar: $error'),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          backgroundColor:
              error == null ? BloomColors.ink : BloomColors.bad,
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: BloomColors.violet,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _TopAppBar(
              onRefresh: onRefresh,
              refreshing: _refreshing,
            ),
            const SizedBox(height: 6),
            _Greeting(
              person: person,
              monthLabel: monthYearLong(currentMonth),
            ),
            const SizedBox(height: 14),
            _HeroCard(
              person: person,
              buckets: cur,
              totalCartao: totalCartao,
              selectedIdx: _selectedSegment,
              onSelect: (i) => setState(() => _selectedSegment = i),
              loading: loading && rows.isEmpty,
              onSeeDetail: () =>
                  context.push('/detalhe?person=${person.name.toLowerCase()}'),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: PersonPills(
                selected: person,
                onChanged: (p) {
                  ref.read(selectedPersonProvider.notifier).state = p;
                  setState(() => _selectedSegment = null);
                },
                totalForPerson: (p) =>
                    p == Person.julio ? juCur.total : daCur.total,
              ),
            ),
            const SizedBox(height: 14),
            _SmallTiles(rows: rows),
            const SizedBox(height: 14),
            _ComparativeCard(
              cur: cur,
              prev: prev,
              deltas: deltas,
              hasPrev: prevAsync.hasValue && prevAsync.value != null,
              previousLabel: ref.watch(previousMonthProvider) ?? '',
            ),
            const SizedBox(height: 18),
            _RecentEntriesSection(asyncLast: lastAsync),
          ],
        ),
      ),
    );
  }
}

class _TopAppBar extends ConsumerWidget {
  final Future<void> Function() onRefresh;
  final bool refreshing;
  const _TopAppBar({required this.onRefresh, required this.refreshing});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 10, 22, 0),
      child: Row(
        children: [
          const BloomLogo(size: 32),
          const SizedBox(width: 10),
          Text(
            'Hook Finance',
            style: BloomTypography.display(
              fontSize: 16,
              letterSpacing: -0.3,
            ),
          ),
          const Spacer(),
          _IconBtn(
            icon: Icons.refresh,
            onTap: onRefresh,
            tooltip: 'Atualizar',
            busy: refreshing,
          ),
          const SizedBox(width: 8),
          _IconBtn(
            icon: Icons.logout,
            onTap: () => ref.read(authProvider.notifier).signOut(),
            tooltip: 'Sair',
          ),
        ],
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final FutureOr<void> Function() onTap;
  final String tooltip;
  final bool busy;
  const _IconBtn({
    required this.icon,
    required this.onTap,
    required this.tooltip,
    this.busy = false,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: busy ? null : () => onTap(),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: BloomColors.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: BloomColors.border, width: 1),
            ),
            alignment: Alignment.center,
            child: busy
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: BloomColors.violet,
                    ),
                  )
                : Icon(icon, size: 16, color: BloomColors.ink),
          ),
        ),
      ),
    );
  }
}

class _Greeting extends StatelessWidget {
  final Person person;
  final String monthLabel;
  const _Greeting({required this.person, required this.monthLabel});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 6, 22, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              style: BloomTypography.geist(
                  fontSize: 13, color: BloomColors.muted),
              children: [
                const TextSpan(text: 'Olá, '),
                TextSpan(
                  text: person.displayName,
                  style: BloomTypography.geist(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const TextSpan(text: ' ✿'),
              ],
            ),
          ),
          const SizedBox(height: 2),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  monthLabel,
                  style: BloomTypography.display(
                    fontSize: 30,
                    letterSpacing: -0.8,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: MonthSelector(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  final Person person;
  final PersonBuckets buckets;
  final double totalCartao;
  final int? selectedIdx;
  final ValueChanged<int?> onSelect;
  final bool loading;
  final VoidCallback onSeeDetail;

  const _HeroCard({
    required this.person,
    required this.buckets,
    required this.totalCartao,
    required this.selectedIdx,
    required this.onSelect,
    required this.loading,
    required this.onSeeDetail,
  });

  @override
  Widget build(BuildContext context) {
    final donutBuckets = [
      DonutBucket(
        label: 'Compart.',
        value: buckets.compart,
        pct: buckets.total == 0 ? 0 : buckets.compart / buckets.total * 100,
      ),
      DonutBucket(
        label: 'Pessoal',
        value: buckets.pessoal,
        pct: buckets.total == 0 ? 0 : buckets.pessoal / buckets.total * 100,
      ),
      DonutBucket(
        label: 'Contas',
        value: buckets.contas,
        pct: buckets.total == 0 ? 0 : buckets.contas / buckets.total * 100,
      ),
    ];
    final colors = [
      BloomColors.violet,
      BloomColors.mint,
      BloomColors.sky,
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: BloomCard(
        soft: true,
        padding: const EdgeInsets.all(18),
        borderRadius: BorderRadius.circular(26),
        child: loading
            ? const SizedBox(
                height: 170,
                child: Center(
                    child: CircularProgressIndicator(
                        color: BloomColors.violet)),
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  BloomDonut(
                    buckets: donutBuckets,
                    total: buckets.total,
                    person: person.displayName,
                    selectedIdx: selectedIdx,
                    onSelect: onSelect,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('CARTÃO GERAL',
                            style: BloomTypography.kicker()),
                        Text(
                          'R\$ ${formatMoney(totalCartao)}',
                          style: BloomTypography.display(
                            fontSize: 22,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        for (var i = 0; i < donutBuckets.length; i++)
                          _BucketLine(
                            color: colors[i],
                            label: donutBuckets[i].label,
                            pct: donutBuckets[i].pct,
                            dim: selectedIdx != null && selectedIdx != i,
                            onTap: () =>
                                onSelect(selectedIdx == i ? null : i),
                          ),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: onSeeDetail,
                          borderRadius: BorderRadius.circular(4),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Text(
                              'Ver pessoal →',
                              style: BloomTypography.geist(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w500,
                                color: BloomColors.violet,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _BucketLine extends StatelessWidget {
  final Color color;
  final String label;
  final double pct;
  final bool dim;
  final VoidCallback onTap;

  const _BucketLine({
    required this.color,
    required this.label,
    required this.pct,
    required this.dim,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: dim ? 0.45 : 1.0,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration:
                    BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: BloomTypography.geist(
                    fontSize: 11.5,
                    color: BloomColors.inkSoft,
                  ),
                ),
              ),
              Text(
                '${pct.toStringAsFixed(0)}%',
                style: BloomTypography.mono(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SmallTiles extends StatelessWidget {
  final List<ExpenseRow> rows;
  const _SmallTiles({required this.rows});

  @override
  Widget build(BuildContext context) {
    final totalCartao = rows
        .where((r) => r.origem == 'Cartão')
        .fold<double>(0, (s, r) => s + r.valor);
    final totalParcelado = rows.where((r) {
      final p = r.parcela;
      if (p.isEmpty) return false;
      final parts = p.split('/');
      if (parts.length != 2) return false;
      final t = int.tryParse(parts[1]) ?? 1;
      return t > 1;
    }).fold<double>(0, (s, r) => s + r.valor);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Row(
        children: [
          Expanded(
            child: _Tile(label: 'Cartão geral', value: totalCartao),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _Tile(label: 'Parcelado', value: totalParcelado),
          ),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  final String label;
  final double value;
  const _Tile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return BloomCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      borderRadius: BorderRadius.circular(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: BloomTypography.kicker()),
          const SizedBox(height: 2),
          Text(
            'R\$ ${formatMoney(value)}',
            style: BloomTypography.display(fontSize: 18, letterSpacing: -0.4),
          ),
        ],
      ),
    );
  }
}

class _ComparativeCard extends StatelessWidget {
  final PersonBuckets cur;
  final PersonBuckets prev;
  final BucketDeltas deltas;
  final bool hasPrev;
  final String previousLabel;

  const _ComparativeCard({
    required this.cur,
    required this.prev,
    required this.deltas,
    required this.hasPrev,
    required this.previousLabel,
  });

  @override
  Widget build(BuildContext context) {
    final cols = [
      _Col(
        label: 'Compart.',
        color: BloomColors.violet,
        value: cur.compart,
        delta: deltas.compart,
      ),
      _Col(
        label: 'Pessoal',
        color: BloomColors.mint,
        value: cur.pessoal,
        delta: deltas.pessoal,
      ),
      _Col(
        label: 'Contas',
        color: BloomColors.sky,
        value: cur.contas,
        delta: deltas.contas,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: BloomCard(
        padding: const EdgeInsets.all(14),
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Expanded(
                  child: Text(
                    hasPrev
                        ? 'COMPARAÇÃO VS. ${previousLabel.toUpperCase()}'
                        : 'BUCKETS',
                    style: BloomTypography.kicker(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (hasPrev)
                  Text(
                    'variação %',
                    style: BloomTypography.mono(
                      fontSize: 10,
                      color: BloomColors.muted,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < cols.length; i++) ...[
                    if (i > 0)
                      const VerticalDivider(
                        width: 1,
                        color: BloomColors.divider,
                      ),
                    Expanded(child: cols[i]),
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

class _Col extends StatelessWidget {
  final String label;
  final Color color;
  final double value;
  final double? delta;

  const _Col({
    required this.label,
    required this.color,
    required this.value,
    required this.delta,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: BloomTypography.kicker(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            'R\$ ${_compact(value)}',
            style: BloomTypography.display(fontSize: 15, letterSpacing: -0.3),
          ),
          const SizedBox(height: 5),
          if (delta != null)
            _DeltaBadge(value: delta!)
          else
            Text(
              '—',
              style: BloomTypography.mono(
                  fontSize: 9.5, color: BloomColors.muted),
            ),
        ],
      ),
    );
  }
}

class _DeltaBadge extends StatelessWidget {
  final double value;
  const _DeltaBadge({required this.value});

  @override
  Widget build(BuildContext context) {
    final up = value > 0;
    final tone = up ? BloomColors.bad : BloomColors.good;
    final symbol = up ? '↗' : '↘';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.094),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$symbol ${value.abs().toStringAsFixed(1).replaceAll('.', ',')}%',
        style: BloomTypography.mono(
          fontSize: 9.5,
          fontWeight: FontWeight.w600,
          color: tone,
        ),
      ),
    );
  }
}

String _compact(double v) {
  if (v.abs() >= 1000) {
    final k = v / 1000;
    return '${k.toStringAsFixed(1).replaceAll('.', ',')}k';
  }
  return formatMoney(v);
}

class _RecentEntriesSection extends ConsumerWidget {
  final AsyncValue<LastEntriesResponse> asyncLast;
  const _RecentEntriesSection({required this.asyncLast});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = asyncLast.value?.entries ?? const <Entry>[];
    final shown = entries.take(2).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: Text(
                  'Últimos lançamentos',
                  style: BloomTypography.display(fontSize: 14),
                ),
              ),
              InkWell(
                onTap: () => ref
                    .read(activeTabProvider.notifier)
                    .state = BloomTab.lancamento,
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Text(
                    'Ver mais →',
                    style: BloomTypography.geist(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: BloomColors.violet,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          BloomCard(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            borderRadius: BorderRadius.circular(18),
            child: shown.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
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
                      for (var i = 0; i < shown.length; i++)
                        RecentEntryRow(
                          entry: shown[i],
                          showDivider: i > 0,
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
