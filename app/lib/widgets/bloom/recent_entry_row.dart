// Spec: docs/specs/cards/recent-entry-row.md

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
  /// Quando true, suprime a hora de `dataRef` e o `splitLabel` na 2ª linha.
  /// Usado em telas onde o rateio já é implícito (ex.: Despesas pessoais).
  final bool compactMeta;

  const RecentEntryRow({
    super.key,
    required this.entry,
    this.onTap,
    this.showDivider = true,
    this.highlightMissing = false,
    this.compactMeta = false,
  });

  @override
  Widget build(BuildContext context) {
    final missing = highlightMissing &&
        (entry.categoria.isEmpty || entry.rateio.isEmpty);
    final tone = missing ? BloomColors.bad : _toneFor(entry.rateio);
    final descColor = missing ? BloomColors.bad : BloomColors.ink;
    final avatarLabel = _avatarLabel(entry.rateio);
    final splitLabel = _splitLabel(entry.rateio);

    final rawDateRef = entry.dataRef.isNotEmpty ? entry.dataRef : entry.data;
    final dateRef = compactMeta ? _stripTime(rawDateRef) : rawDateRef;
    final cat = entry.categoria.isEmpty ? '—' : entry.categoria;
    final parcelaSuffix = _parcelaSuffix(entry.parcela);
    final meta = compactMeta
        ? '$dateRef$parcelaSuffix'
        : '$dateRef · $cat · $splitLabel$parcelaSuffix';

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
            avatarLabel,
            style: BloomTypography.display(
              fontSize: 12,
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
                meta,
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
    if (rateio == 'Metade' || rateio.isEmpty) return BloomColors.muted;
    if (rateio == 'Dani') return BloomColors.forPerson(Person.dani);
    if (rateio == 'Julio') return BloomColors.forPerson(Person.julio);
    return BloomColors.amber;
  }

  String _avatarLabel(String rateio) {
    if (rateio == 'Metade') return '½';
    if (rateio.isEmpty) return '?';
    return rateio.characters.first.toUpperCase();
  }

  String _splitLabel(String rateio) {
    if (rateio == 'Metade') return 'dividido';
    if (rateio.isEmpty) return '—';
    return rateio;
  }

  String _parcelaSuffix(String parcela) {
    final s = parcela.trim();
    if (s.isEmpty || !s.contains('/')) return '';
    final parts = s.split('/');
    if (parts.length != 2) return '';
    final x = int.tryParse(parts[0]);
    final y = int.tryParse(parts[1]);
    if (x == null || y == null || y <= 0) return '';
    return ' · ($x / $y)';
  }

  String _stripTime(String s) {
    final i = s.indexOf(' ');
    return i < 0 ? s : s.substring(0, i);
  }
}
