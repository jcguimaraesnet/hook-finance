// Spec: docs/specs/pages/acerto.md
// Acerto (Bloom) — hero gradient + selector D/J + 1 tabela ativa (Dani default).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/format/money.dart';
import '../../core/rules/bucket_deltas.dart';
import '../../core/rules/diff_calculation.dart';
import '../../core/rules/split_for_person.dart';
import '../../core/types.dart';
import '../../state/data_providers.dart';
import '../../theme/bloom_colors.dart';
import '../../theme/bloom_typography.dart';
import '../../widgets/bloom/bloom_card.dart';
import '../../widgets/bloom/month_selector.dart';
import '../../widgets/bloom/screen_header.dart';

class AcertoPage extends ConsumerStatefulWidget {
  const AcertoPage({super.key});

  @override
  ConsumerState<AcertoPage> createState() => _AcertoPageState();
}

class _AcertoPageState extends ConsumerState<AcertoPage> {
  Person _selected = Person.dani;

  @override
  Widget build(BuildContext context) {
    final currentMonth = ref.watch(currentMonthProvider);
    final monthAsync = ref.watch(monthDataProvider(currentMonth));
    final rows = monthAsync.value?.rows ?? const <ExpenseRow>[];
    final loading = monthAsync.isLoading && !monthAsync.hasValue;

    final daniBuckets = bucketsForPerson(rows, Person.dani);

    Future<void> onRefresh() async {
      ref.invalidate(monthDataProvider);
      try {
        await ref.read(monthDataProvider(currentMonth).future);
      } catch (_) {}
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
            const ScreenHeader(
              kicker: 'Acerto',
              title: 'Acerto Final',
              trailing: MonthSelector(),
            ),
            const SizedBox(height: 12),
            _Hero(
              total: daniBuckets.total,
              selected: _selected,
              onSelect: (p) => setState(() => _selected = p),
            ),
            const SizedBox(height: 14),
            if (loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: CircularProgressIndicator(
                      color: BloomColors.violet),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: _PersonAcertoCard(
                  person: _selected,
                  rows: rows,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  final double total;
  final Person selected;
  final ValueChanged<Person> onSelect;

  const _Hero({
    required this.total,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [BloomColors.violet, BloomColors.sky],
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: BloomColors.violet.withValues(alpha: 0.30),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'DANI TRANSFERE PARA JÚLIO',
                    style: BloomTypography.geist(
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.85),
                      letterSpacing: 0.4,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'R\$ ${formatMoney(total)}',
                      maxLines: 1,
                      style: BloomTypography.display(
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        height: 1.05,
                        letterSpacing: -0.6,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _PersonOrb(
                  letter: 'D',
                  active: selected == Person.dani,
                  invertedActive: true,
                  onTap: () => onSelect(Person.dani),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Text(
                    '↔',
                    style: BloomTypography.geist(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                ),
                _PersonOrb(
                  letter: 'J',
                  active: selected == Person.julio,
                  invertedActive: false,
                  onTap: () => onSelect(Person.julio),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PersonOrb extends StatelessWidget {
  final String letter;
  final bool active;
  final bool invertedActive;
  final VoidCallback onTap;

  const _PersonOrb({
    required this.letter,
    required this.active,
    required this.invertedActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final inverted = invertedActive;
    final bg = inverted
        ? Colors.white.withValues(alpha: 0.25)
        : Colors.white;
    final fg = inverted ? Colors.white : BloomColors.violet;
    final activeBorder = active
        ? Border.all(
            color: inverted ? Colors.white : BloomColors.violet,
            width: 2,
          )
        : Border.all(color: Colors.transparent, width: 2);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: bg,
          shape: BoxShape.circle,
          border: activeBorder,
        ),
        alignment: Alignment.center,
        child: Text(
          letter,
          style: BloomTypography.display(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: fg,
            height: 1,
          ),
        ),
      ),
    );
  }
}

class _PersonAcertoCard extends ConsumerWidget {
  final Person person;
  final List<ExpenseRow> rows;

  const _PersonAcertoCard({required this.person, required this.rows});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final personColor = BloomColors.forPerson(person);
    final isJulio = person == Person.julio;
    final pixExpanded = ref.watch(acertoPixJulioProvider) && isJulio;

    final cartao = rows.where((r) => r.origem == 'Cartão');
    final cartaoCompart = cartao
        .where((r) => r.rateio == 'Metade')
        .fold<double>(0, (s, r) => s + splitForPerson(r, person));
    final cartaoPessoal = cartao
        .where((r) => r.rateio == person.name)
        .fold<double>(0, (s, r) => s + splitForPerson(r, person));

    // Para Júlio com toggle expandido, mostra todas as Pix dele (sem filtro
    // por `acerto == 'Sim'`). Mantém o comportamento legado do PWA.
    final pixRows = rows
        .where((r) =>
            r.origem == 'Pix (contas)' &&
            r.rateio == person.name &&
            (pixExpanded || r.acerto == 'Sim'))
        .toList();
    final pixSubtotal =
        pixRows.fold<double>(0, (s, r) => s + r.valor);
    final total = cartaoCompart + cartaoPessoal + pixSubtotal;

    final diff = diffCalculation(rows, person).abs();

    return BloomCard(
      padding: EdgeInsets.zero,
      borderRadius: BorderRadius.circular(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: const Alignment(-0.95, 0),
                end: const Alignment(0.95, 0),
                colors: [
                  personColor.withValues(alpha: 0.094),
                  personColor.withValues(alpha: 0.024),
                ],
              ),
              border: const Border(
                bottom: BorderSide(color: BloomColors.divider, width: 1),
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(22),
                topRight: Radius.circular(22),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: personColor,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    person == Person.julio ? 'J' : 'D',
                    style: BloomTypography.display(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    person.displayName,
                    style: BloomTypography.display(
                      fontSize: 17,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: personColor.withValues(alpha: 0.13),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Diferença ',
                        style: BloomTypography.mono(
                          fontSize: 10.5,
                          color:
                              personColor.withValues(alpha: 0.85),
                        ),
                      ),
                      Text(
                        'R\$ ${formatMoney(diff)}',
                        style: BloomTypography.mono(
                          fontSize: 10.5,
                          color: personColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Column headers
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 4),
            child: Row(
              children: [
                Expanded(
                    child: Text('DESPESA',
                        style: BloomTypography.kicker())),
                SizedBox(
                  width: 80,
                  child: Text(
                    'VALOR',
                    textAlign: TextAlign.right,
                    style: BloomTypography.kicker(),
                  ),
                ),
                SizedBox(
                  width: 50,
                  child: Text(
                    '%',
                    textAlign: TextAlign.right,
                    style: BloomTypography.kicker(),
                  ),
                ),
              ],
            ),
          ),
          // Cartão rows
          _DataRow(
            label: 'Cartão (compartilhado)',
            value: cartaoCompart,
            total: total,
          ),
          _DataRow(
            label: 'Cartão (pessoal)',
            value: cartaoPessoal,
            total: total,
          ),
          // Pix subheader — clicável apenas para Júlio (expande/recolhe)
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 4),
            child: InkWell(
              onTap: isJulio
                  ? () => ref
                      .read(acertoPixJulioProvider.notifier)
                      .state = !pixExpanded
                  : null,
              child: Container(
                padding: const EdgeInsets.only(bottom: 3),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                        color: BloomColors.divider, width: 1),
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      'Pix · Contas',
                      style: BloomTypography.geist(
                        fontSize: 11,
                        color: BloomColors.inkSoft,
                        fontWeight: FontWeight.w600,
                      ).copyWith(
                        decoration:
                            isJulio ? TextDecoration.underline : null,
                        decorationColor: BloomColors.divider,
                      ),
                    ),
                    if (isJulio) ...[
                      const SizedBox(width: 6),
                      Icon(
                        pixExpanded
                            ? Icons.expand_less
                            : Icons.expand_more,
                        size: 14,
                        color: BloomColors.muted,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          if (pixRows.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 18, vertical: 12),
              child: Text(
                'Sem Pix de acerto.',
                style: BloomTypography.geist(
                  fontSize: 12,
                  color: BloomColors.muted,
                ),
              ),
            )
          else
            for (final r in pixRows)
              _DataRow(
                label: r.descricao.isEmpty ? '—' : r.descricao,
                value: r.valor,
                total: pixSubtotal,
                small: true,
              ),
          // Subtotal Pix
          Container(
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: BloomColors.divider, width: 1),
              ),
            ),
            child: _DataRow(
              label: 'Subtotal Pix',
              labelStyle: BloomTypography.geist(
                fontSize: 12,
                color: BloomColors.inkSoft,
              ).copyWith(fontStyle: FontStyle.italic),
              value: pixSubtotal,
              total: total,
            ),
          ),
          // Total Pessoal
          Container(
            decoration: const BoxDecoration(
              color: BloomColors.bg3,
              border: Border(
                top: BorderSide(color: BloomColors.ink, width: 2),
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(22),
                bottomRight: Radius.circular(22),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 18, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Total Pessoal',
                      style: BloomTypography.display(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 80,
                    child: Text(
                      formatMoney(total),
                      textAlign: TextAlign.right,
                      style: BloomTypography.mono(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 50,
                    child: Text(
                      '100%',
                      textAlign: TextAlign.right,
                      style: BloomTypography.mono(
                        fontSize: 11,
                        color: BloomColors.muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DataRow extends StatelessWidget {
  final String label;
  final TextStyle? labelStyle;
  final double value;
  final double total;
  final bool small;

  const _DataRow({
    required this.label,
    required this.value,
    required this.total,
    this.labelStyle,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    final pct = total == 0 ? 0.0 : (value / total) * 100;
    return Padding(
      padding: EdgeInsets.symmetric(
          horizontal: 18, vertical: small ? 7 : 9),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: labelStyle ??
                  BloomTypography.geist(
                    fontSize: small ? 12 : 12.5,
                    color: small ? BloomColors.inkSoft : BloomColors.ink,
                  ),
            ),
          ),
          SizedBox(
            width: 80,
            child: Text(
              formatMoney(value),
              textAlign: TextAlign.right,
              style: BloomTypography.mono(
                fontSize: small ? 11.5 : 12,
                color: small ? BloomColors.inkSoft : BloomColors.ink,
              ),
            ),
          ),
          SizedBox(
            width: 50,
            child: Text(
              '${pct.toStringAsFixed(1).replaceAll('.', ',')}%',
              textAlign: TextAlign.right,
              style: BloomTypography.mono(
                fontSize: small ? 10 : 10.5,
                color: BloomColors.muted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
