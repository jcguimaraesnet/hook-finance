// Spec: docs/specs/pages/consulta.md

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/types.dart';
import '../../state/data_providers.dart';
import '../../theme/breakpoints.dart';
import '../../widgets/categoria_table.dart';
import '../../widgets/historico_chart.dart';
import '../../widgets/person_card.dart';
import '../../widgets/rateio_chart.dart';
import '../../widgets/sticky_header.dart';

class ConsultaPage extends ConsumerStatefulWidget {
  const ConsultaPage({super.key});

  @override
  ConsumerState<ConsultaPage> createState() => _ConsultaPageState();
}

class _ConsultaPageState extends ConsumerState<ConsultaPage>
    with TickerProviderStateMixin {
  TabController? _controller;

  @override
  void initState() {
    super.initState();
    _controller = TabController(length: 4, vsync: this);

    // Auto-set currentMonth quando monthData chegar (equivalente ao useEffect do PWA).
    ref.listenManual<AsyncValue<MonthDataResponse>>(
      monthDataProvider(null),
      (_, next) {
        next.whenData((d) {
          final cur = ref.read(currentMonthProvider);
          if (cur == null && d.month != null) {
            ref.read(currentMonthProvider.notifier).state = d.month;
          }
        });
      },
      fireImmediately: true,
    );

    // Auto-popular allMonths quando historicalSummary chegar.
    ref.listenManual<AsyncValue<HistoricalSummaryResponse>>(
      historicalSummaryProvider,
      (_, next) {
        next.whenData((d) {
          if (d.months.isNotEmpty) {
            ref.read(allMonthsProvider.notifier).state = d.months;
          }
        });
      },
      fireImmediately: true,
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isPC = context.isPC;
    final currentMonth = ref.watch(currentMonthProvider);
    final monthAsync = ref.watch(monthDataProvider(currentMonth));
    final historyAsync = ref.watch(historicalSummaryProvider);
    final rows = monthAsync.value?.rows ?? const <ExpenseRow>[];
    final loading = monthAsync.isLoading && !monthAsync.hasValue;

    if (monthAsync.hasError && !monthAsync.hasValue) {
      return _ErrorView(
        error: monthAsync.error!,
        onRetry: () => ref.invalidate(monthDataProvider),
      );
    }

    final mes = _MesPanel(rows: rows, loading: loading);
    final categoria = _CategoriaPanel(rows: rows, loading: loading, isPC: isPC);
    final pessoal = _PessoalPanel(rows: rows, loading: loading);
    final historico = _HistoricoPanel(historyAsync: historyAsync);

    Future<void> onRefresh() async {
      ref.invalidate(monthDataProvider);
      ref.invalidate(historicalSummaryProvider);
      // Espera as refetches completarem antes de fechar o spinner.
      await Future.wait([
        ref.read(monthDataProvider(currentMonth).future),
        ref.read(historicalSummaryProvider.future),
      ]).catchError((_) => <Object>[]);
    }

    if (isPC) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const StickyHeader(),
              const SizedBox(height: 12),
              mes,
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: categoria),
                  const SizedBox(width: 12),
                  Expanded(child: pessoal),
                ],
              ),
              const SizedBox(height: 12),
              historico,
            ],
          ),
        ),
      );
    }

    Widget tabPanel(Widget child) => RefreshIndicator(
          onRefresh: onRefresh,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(12),
            child: child,
          ),
        );

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          child: const StickyHeader(),
        ),
        TabBar(
          controller: _controller,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: const [
            Tab(text: 'Mês'),
            Tab(text: 'Categoria'),
            Tab(text: 'Pessoal'),
            Tab(text: 'Histórico'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _controller,
            children: [
              tabPanel(mes),
              tabPanel(categoria),
              tabPanel(pessoal),
              tabPanel(historico),
            ],
          ),
        ),
      ],
    );
  }
}

class _MesPanel extends StatelessWidget {
  final List<ExpenseRow> rows;
  final bool loading;
  const _MesPanel({required this.rows, required this.loading});

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const _LoadingCards(count: 2);
    }
    final isTablet = context.isTabletOrUp;
    final cards = [
      PersonCard(person: Person.julio, rows: rows),
      PersonCard(person: Person.dani, rows: rows),
    ];
    if (isTablet) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: cards[0]),
          const SizedBox(width: 12),
          Expanded(child: cards[1]),
        ],
      );
    }
    return Column(
      children: [
        cards[0],
        const SizedBox(height: 12),
        cards[1],
      ],
    );
  }
}

class _CategoriaPanel extends StatelessWidget {
  final List<ExpenseRow> rows;
  final bool loading;
  final bool isPC;
  const _CategoriaPanel({
    required this.rows,
    required this.loading,
    required this.isPC,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) return const _LoadingCards(count: 1);
    return CategoriaTable(rows: rows);
  }
}

class _PessoalPanel extends StatelessWidget {
  final List<ExpenseRow> rows;
  final bool loading;
  const _PessoalPanel({required this.rows, required this.loading});

  @override
  Widget build(BuildContext context) {
    if (loading) return const _LoadingCards(count: 1);
    return RateioChart(rows: rows);
  }
}

class _HistoricoPanel extends StatelessWidget {
  final AsyncValue<HistoricalSummaryResponse> historyAsync;
  const _HistoricoPanel({required this.historyAsync});

  @override
  Widget build(BuildContext context) {
    if (historyAsync.isLoading && !historyAsync.hasValue) {
      return const _LoadingCards(count: 2);
    }
    final h = historyAsync.value?.history;
    if (h == null) {
      return const Center(child: Text('Sem histórico'));
    }
    return Column(
      children: [
        HistoricoChart(
          title: 'Histórico — Total geral',
          months: h.months,
          series: [
            HistoricoSeries(
              label: 'Total geral',
              data: h.totals,
              color: const Color(0xFFA07B5E),
            ),
          ],
          showLegend: false,
        ),
        const SizedBox(height: 12),
        HistoricoChart(
          title: 'Histórico — Pessoal',
          months: h.months,
          series: [
            HistoricoSeries(
              label: 'Júlio',
              data: h.julioPessoal,
              color: const Color(0xFF4A7AB8),
            ),
            HistoricoSeries(
              label: 'Dani',
              data: h.daniPessoal,
              color: const Color(0xFFC97070),
            ),
          ],
        ),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;
  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline,
              size: 48, color: theme.colorScheme.error),
          const SizedBox(height: 12),
          Text(
            'Falha carregando dados',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            '$error',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Tentar de novo'),
          ),
        ],
      ),
    );
  }
}

class _LoadingCards extends StatelessWidget {
  final int count;
  const _LoadingCards({required this.count});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < count; i++) ...[
          if (i > 0) const SizedBox(height: 12),
          Card(
            child: SizedBox(
              height: 160,
              child: Center(
                child: CircularProgressIndicator(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
