// Linha de lançamento — avatar com inicial + merchant/data·cat·split + valor.

import 'package:flutter/material.dart';
import '../../core/format/money.dart';
import '../../core/types.dart';
import '../../theme/bloom_colors.dart';
import '../../theme/bloom_typography.dart';

class RecentEntryRow extends StatelessWidget {
  final ExpenseRow entry;
  final VoidCallback? onTap;
  final bool showDivider;
  /// Quando true e o entry tem categoria ou rateio vazios, destaca em vermelho.
  final bool highlightMissing;

  const RecentEntryRow({
    super.key,
    required this.entry,
    this.onTap,
    this.showDivider = true,
    this.highlightMissing = false,
  });

  @override
  Widget build(BuildContext context) {
    final missing = highlightMissing &&
        (entry.categoria.isEmpty || entry.rateio.isEmpty);
    final initial = entry.descricao.isEmpty
        ? '?'
        : entry.descricao.characters.first.toUpperCase();
    final tone = missing ? BloomColors.bad : _toneFor(entry.rateio);
    final descColor = missing ? BloomColors.bad : BloomColors.ink;
    final splitLabel = _splitLabel(entry.rateio);

    final dateRef = entry.dataRef.isNotEmpty ? entry.dataRef : entry.data;
    final cat = entry.categoria.isEmpty ? '—' : entry.categoria;

    final row = Row(
      children: [
        Container(
          width: 30,
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: tone.withValues(alpha: 0.13),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Text(
            initial,
            style: BloomTypography.display(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: tone,
              height: 1,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                entry.descricao.isEmpty ? '—' : entry.descricao,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: BloomTypography.geist(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: descColor,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                '$dateRef · $cat · $splitLabel',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: BloomTypography.mono(
                  fontSize: 10,
                  color: BloomColors.muted,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Text(
          'R\$ ${formatMoney(entry.valor)}',
          style: BloomTypography.mono(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        if (onTap != null) ...[
          const SizedBox(width: 6),
          const Icon(Icons.chevron_right,
              size: 14, color: BloomColors.muted),
        ],
      ],
    );

    final padded = Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: row,
    );

    final content = showDivider
        ? Container(
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: BloomColors.divider, width: 1),
              ),
            ),
            child: padded,
          )
        : padded;

    if (onTap == null) return content;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: content,
      ),
    );
  }

  Color _toneFor(String rateio) {
    if (rateio == 'Metade' || rateio.isEmpty) return BloomColors.violet;
    if (rateio == 'Dani') return BloomColors.mint;
    if (rateio == 'Julio') return BloomColors.amber;
    return BloomColors.sky;
  }

  String _splitLabel(String rateio) {
    if (rateio == 'Metade') return 'dividido';
    if (rateio.isEmpty) return '—';
    return rateio;
  }
}
