// Tabs Júlio/Dani — fundo `ink` quando ativo, fundo `card` senão.

import 'package:flutter/material.dart';
import '../../core/format/money.dart';
import '../../core/types.dart';
import '../../theme/bloom_colors.dart';
import '../../theme/bloom_typography.dart';

class PersonPills extends StatelessWidget {
  final Person selected;
  final ValueChanged<Person> onChanged;
  final double Function(Person) totalForPerson;

  const PersonPills({
    super.key,
    required this.selected,
    required this.onChanged,
    required this.totalForPerson,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < Person.values.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: _Pill(
              person: Person.values[i],
              active: selected == Person.values[i],
              total: totalForPerson(Person.values[i]),
              onTap: () => onChanged(Person.values[i]),
            ),
          ),
        ],
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  final Person person;
  final bool active;
  final double total;
  final VoidCallback onTap;

  const _Pill({
    required this.person,
    required this.active,
    required this.total,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final personColor = BloomColors.forPerson(person);
    final initial = person == Person.julio ? 'J' : 'D';
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          decoration: BoxDecoration(
            color: active ? BloomColors.ink : BloomColors.card,
            borderRadius: BorderRadius.circular(18),
            border: active
                ? null
                : Border.all(color: BloomColors.border, width: 1),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: BloomColors.ink.withValues(alpha: 0.18),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: personColor,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  initial,
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      person.displayName,
                      style: BloomTypography.geist(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: active ? Colors.white : BloomColors.inkSoft,
                      ),
                    ),
                    Text(
                      'R\$ ${formatMoney(total)}',
                      style: BloomTypography.mono(
                        fontSize: 10.5,
                        color: active
                            ? Colors.white.withValues(alpha: 0.7)
                            : BloomColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

