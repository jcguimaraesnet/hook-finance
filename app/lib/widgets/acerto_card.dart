// Spec: docs/specs/cards/acerto-card.md

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/format/money.dart';
import '../core/rules/diff_calculation.dart';
import '../core/rules/split_for_person.dart';
import '../core/types.dart';
import '../state/data_providers.dart';
import '../state/diff_toggle.dart';

class AcertoCard extends ConsumerWidget {
  final Person person;
  final List<ExpenseRow> rows;
  final bool loading;

  const AcertoCard({
    super.key,
    required this.person,
    required this.rows,
    required this.loading,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final showDiff = ref.watch(diffVisibleProvider(person));
    final acertoPixJulio = ref.watch(acertoPixJulioProvider);
    final isJulio = person == Person.julio;
    final expanded = isJulio && acertoPixJulio;

    final cartao = rows.where((r) => r.origem == 'Cartão');
    final cartaoCompart = cartao
        .where((r) => r.rateio == 'Metade')
        .fold<double>(0, (s, r) => s + splitForPerson(r, person));
    final cartaoPessoal = cartao
        .where((r) => r.rateio == 'Julio' || r.rateio == 'Dani')
        .fold<double>(0, (s, r) => s + splitForPerson(r, person));

    final pixAllForPerson = rows
        .where((r) => r.origem == 'Pix (contas)' && r.rateio == person.name)
        .toList();
    final pixAcerto = pixAllForPerson.where((r) => r.acerto == 'Sim').toList();
    final pixVisible = expanded ? pixAllForPerson : pixAcerto;

    final showSection =
        isJulio ? pixAllForPerson.isNotEmpty : pixAcerto.isNotEmpty;

    var total = cartaoCompart + cartaoPessoal;
    for (final r in pixVisible) {
      total += r.valor;
    }

    final diff = diffCalculation(rows, person);
    final diffPositive = diff >= 0;
    final diffSign = diffPositive ? '+' : '−';
    final diffColor = diffPositive
        ? const Color(0xFF2C5AA0)
        : theme.colorScheme.error;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            _Header(
              person: person,
              showDiff: showDiff,
              diff: diff,
              diffSign: diffSign,
              diffColor: diffColor,
              onToggle: () => ref
                  .read(diffVisibleProvider(person).notifier)
                  .state = !showDiff,
            ),
            const SizedBox(height: 8),
            if (loading)
              ...List.generate(
                3,
                (_) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Container(
                    height: 16,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              )
            else
              _Content(
                cartaoCompart: cartaoCompart,
                cartaoPessoal: cartaoPessoal,
                showSection: showSection,
                pixVisible: pixVisible,
                total: total,
                isJulio: isJulio,
                onTogglePix: () => ref
                    .read(acertoPixJulioProvider.notifier)
                    .state = !acertoPixJulio,
              ),
          ],
        ),
      ),
    );
  }
}

class _Content extends StatelessWidget {
  final double cartaoCompart;
  final double cartaoPessoal;
  final bool showSection;
  final List<ExpenseRow> pixVisible;
  final double total;
  final bool isJulio;
  final VoidCallback onTogglePix;

  const _Content({
    required this.cartaoCompart,
    required this.cartaoPessoal,
    required this.showSection,
    required this.pixVisible,
    required this.total,
    required this.isJulio,
    required this.onTogglePix,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderSide = BorderSide(color: theme.colorScheme.outlineVariant);
    final cellStyle = theme.textTheme.bodySmall?.copyWith(
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    final boldStyle = cellStyle?.copyWith(fontWeight: FontWeight.bold);
    final headerStyle = theme.textTheme.labelSmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
      fontWeight: FontWeight.w600,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: Text('Despesas agrupadas', style: headerStyle)),
            Text('Valor (R\$)', style: headerStyle),
          ],
        ),
        const SizedBox(height: 4),
        DecoratedBox(
          decoration: BoxDecoration(
            border: Border(bottom: borderSide),
          ),
          child: _Row(label: 'Cartão (compartilhado)', value: cartaoCompart, style: cellStyle),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            border: Border(bottom: borderSide),
          ),
          child: _Row(label: 'Cartão (pessoal)', value: cartaoPessoal, style: cellStyle),
        ),
        if (showSection) ...[
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 4),
            child: isJulio
                ? InkWell(
                    onTap: onTogglePix,
                    child: Text(
                      'Pix (contas)',
                      style: headerStyle?.copyWith(
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  )
                : Text('Pix (contas)', style: headerStyle),
          ),
          for (final r in pixVisible)
            DecoratedBox(
              decoration: BoxDecoration(
                border: Border(bottom: borderSide),
              ),
              child: _Row(
                label: r.descricao,
                value: r.valor,
                style: cellStyle,
                truncate: true,
              ),
            ),
        ],
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(
                color: theme.colorScheme.onSurface,
                width: 1.5,
              )),
            ),
            child: _Row(label: 'Total Pessoal', value: total, style: boldStyle),
          ),
        ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final double value;
  final TextStyle? style;
  final bool truncate;
  const _Row({
    required this.label,
    required this.value,
    this.style,
    this.truncate = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: style,
              overflow: truncate ? TextOverflow.ellipsis : null,
              maxLines: truncate ? 1 : null,
            ),
          ),
          Text(formatMoney(value), style: style),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final Person person;
  final bool showDiff;
  final double diff;
  final String diffSign;
  final Color diffColor;
  final VoidCallback onToggle;

  const _Header({
    required this.person,
    required this.showDiff,
    required this.diff,
    required this.diffSign,
    required this.diffColor,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF4D35E),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Text(
            person.displayName,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: const Color(0xFF262626),
            ),
          ),
          Positioned(
            right: 36,
            child: AnimatedOpacity(
              opacity: showDiff ? 1 : 0,
              duration: const Duration(milliseconds: 200),
              child: Text(
                '$diffSign R\$ ${formatMoney(diff.abs())}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: diffColor,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ),
          Positioned(
            right: 0,
            child: InkWell(
              onTap: onToggle,
              borderRadius: BorderRadius.circular(4),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: showDiff
                      ? const Color(0xFF262626)
                      : Colors.black.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Δ',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: showDiff ? Colors.white : const Color(0xFF262626),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
