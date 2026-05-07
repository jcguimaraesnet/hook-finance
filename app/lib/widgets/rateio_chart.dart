// Spec: docs/specs/cards/rateio-chart.md
//
// Diferente do PWA (Chart.js bar horizontal), aqui usamos barras horizontais
// nativas (Stack + Container com largura proporcional). Mais limpo no mobile,
// mesma semântica: nome dentro, valor à direita, ordem desc por valor.

import 'package:flutter/material.dart';
import '../core/format/money.dart';
import '../core/types.dart';

class RateioChart extends StatelessWidget {
  final List<ExpenseRow> rows;
  const RateioChart({super.key, required this.rows});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cartao = rows.where((r) => r.origem == 'Cartão');
    final byRateio = <String, double>{};
    for (final r in cartao) {
      final k = r.rateio.isEmpty ? '(sem rateio)' : r.rateio;
      byRateio[k] = (byRateio[k] ?? 0) + r.valor;
    }
    final data = byRateio.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final maxV = data.isEmpty
        ? 1.0
        : data.map((e) => e.value).reduce((a, b) => a > b ? a : b);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 6, top: 4, bottom: 8),
              child: Text('Cartão (por pessoa)',
                  style: theme.textTheme.titleSmall),
            ),
            if (data.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    'Sem dados',
                    style: TextStyle(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              )
            else
              ...data.map((e) => _RateioBar(
                    label: e.key == 'Metade' ? 'Compartilhado' : e.key,
                    value: e.value,
                    maxValue: maxV,
                  )),
          ],
        ),
      ),
    );
  }
}

class _RateioBar extends StatelessWidget {
  final String label;
  final double value;
  final double maxValue;

  const _RateioBar({
    required this.label,
    required this.value,
    required this.maxValue,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = maxValue > 0 ? value / maxValue : 0.0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
      child: Row(
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    Container(
                      height: 28,
                      width: constraints.maxWidth * ratio,
                      decoration: BoxDecoration(
                        color: const Color(0xFFA07B5E),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        label,
                        style: TextStyle(
                          color: ratio > 0.15
                              ? Colors.white
                              : const Color(0xFF262626),
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 80,
            child: Text(
              formatMoney(value),
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontFeatures: [FontFeature.tabularFigures()],
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
