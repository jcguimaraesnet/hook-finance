// Spec: docs/specs/pages/lancamento.md
// Lançamentos (Bloom) — 2 tabs: lista (10 últimos) + Novo (form stub).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/types.dart';
import '../../state/auth_provider.dart';
import '../../state/data_providers.dart';
import '../../theme/bloom_colors.dart';
import '../../theme/bloom_typography.dart';
import '../../widgets/bloom/bloom_card.dart';
import '../../widgets/bloom/recent_entry_row.dart';
import '../../widgets/bloom/screen_header.dart';
import 'edit_dialog.dart';

class LancamentoPage extends ConsumerStatefulWidget {
  const LancamentoPage({super.key});

  @override
  ConsumerState<LancamentoPage> createState() => _LancamentoPageState();
}

enum _Tab { edit, novo }

class _LancamentoPageState extends ConsumerState<LancamentoPage> {
  _Tab _tab = _Tab.edit;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const ScreenHeader(title: 'Lançamento'),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: _TabSwitcher(
              tab: _tab,
              onChange: (t) => setState(() => _tab = t),
            ),
          ),
          const SizedBox(height: 14),
          if (_tab == _Tab.edit)
            const _EditList()
          else
            _NovoForm(onCancel: () => setState(() => _tab = _Tab.edit)),
        ],
      ),
    );
  }
}

class _TabSwitcher extends StatelessWidget {
  final _Tab tab;
  final ValueChanged<_Tab> onChange;

  const _TabSwitcher({required this.tab, required this.onChange});

  @override
  Widget build(BuildContext context) {
    Widget btn(_Tab t, String label) {
      final active = tab == t;
      return Expanded(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => onChange(t),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 9),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: active ? BloomColors.ink : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                label,
                style: BloomTypography.geist(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: active ? Colors.white : BloomColors.inkSoft,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: BloomColors.card,
        border: Border.all(color: BloomColors.border, width: 1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          btn(_Tab.edit, 'Lançamentos'),
          btn(_Tab.novo, '+ Novo'),
        ],
      ),
    );
  }
}

class _EditList extends ConsumerWidget {
  const _EditList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lastAsync = ref.watch(lastEntriesProvider(10));
    final monthAsync = ref.watch(monthDataProvider(null));
    final entries = lastAsync.value?.entries ?? const <Entry>[];
    final loading = lastAsync.isLoading && !lastAsync.hasValue;

    Future<void> openEdit(Entry e) async {
      final api = ref.read(apiProvider);
      final saved = await showDialog<bool>(
        context: context,
        builder: (_) => EditDialog(
          entry: e,
          rowsForCategoriaSuggestions:
              monthAsync.value?.rows ?? const <ExpenseRow>[],
          api: api,
        ),
      );
      if (saved == true) {
        ref.invalidate(lastEntriesProvider);
        ref.invalidate(monthDataProvider);
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  'ÚLTIMOS 10 · TOQUE PARA EDITAR',
                  style: BloomTypography.kicker(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          BloomCard(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            borderRadius: BorderRadius.circular(22),
            child: loading
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: CircularProgressIndicator(
                          color: BloomColors.violet),
                    ),
                  )
                : entries.isEmpty
                    ? Padding(
                        padding:
                            const EdgeInsets.symmetric(vertical: 24),
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
                          for (var i = 0; i < entries.length; i++)
                            RecentEntryRow(
                              entry: entries[i],
                              showDivider: i > 0,
                              onTap: () => openEdit(entries[i]),
                            ),
                        ],
                      ),
          ),
        ],
      ),
    );
  }
}

class _NovoForm extends StatefulWidget {
  final VoidCallback onCancel;
  const _NovoForm({required this.onCancel});

  @override
  State<_NovoForm> createState() => _NovoFormState();
}

class _NovoFormState extends State<_NovoForm> {
  static const _cats = [
    'Mercado',
    'Restaurante',
    'Farmácia',
    'Transporte',
    'Casa',
    'Pessoal',
    'Viagem',
    'Presente',
  ];

  String _cat = 'Mercado';
  String _paid = 'Cartão';
  String _split = 'Metade';
  final _descCtrl = TextEditingController();

  @override
  void dispose() {
    _descCtrl.dispose();
    super.dispose();
  }

  void _onSave() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Criação manual ainda não implementada. '
          'Lançamentos chegam pelo webhook do Apps Script.',
        ),
        backgroundColor: BloomColors.ink,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [BloomColors.violet, BloomColors.sky],
              ),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: BloomColors.violet.withValues(alpha: 0.25),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'VALOR',
                  style: BloomTypography.geist(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.85),
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      'R\$',
                      style: BloomTypography.geist(
                        fontSize: 18,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '0,00',
                      style: BloomTypography.display(
                        fontSize: 46,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        height: 1,
                        letterSpacing: -1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Stub — chega pelo webhook',
                  style: BloomTypography.geist(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _FieldLabel(label: 'ESTABELECIMENTO'),
          const SizedBox(height: 6),
          TextField(
            controller: _descCtrl,
            decoration: const InputDecoration(
              hintText: 'Ex: Mercado Extra',
              isDense: true,
            ),
          ),
          const SizedBox(height: 14),
          _FieldLabel(label: 'CATEGORIA'),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final c in _cats)
                _ChoiceChip(
                  label: c,
                  active: _cat == c,
                  onTap: () => setState(() => _cat = c),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _FieldLabel(label: 'FORMA'),
                    const SizedBox(height: 6),
                    _Segmented(
                      options: const ['Cartão', 'Pix'],
                      selected: _paid,
                      onChange: (v) => setState(() => _paid = v),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _FieldLabel(label: 'DIVISÃO'),
                    const SizedBox(height: 6),
                    _Segmented(
                      options: const ['Metade', 'Julio', 'Dani'],
                      selected: _split,
                      onChange: (v) => setState(() => _split = v),
                      compact: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _onSave,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                height: 50,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: BloomColors.ink,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  'Salvar lançamento',
                  style: BloomTypography.display(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.2,
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

class _FieldLabel extends StatelessWidget {
  final String label;
  const _FieldLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(label, style: BloomTypography.kicker());
  }
}

class _ChoiceChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _ChoiceChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
          decoration: BoxDecoration(
            color: active ? BloomColors.ink : BloomColors.card,
            borderRadius: BorderRadius.circular(999),
            border: active
                ? null
                : Border.all(color: BloomColors.border, width: 1),
          ),
          child: Text(
            label,
            style: BloomTypography.geist(
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              color: active ? Colors.white : BloomColors.inkSoft,
            ),
          ),
        ),
      ),
    );
  }
}

class _Segmented extends StatelessWidget {
  final List<String> options;
  final String selected;
  final ValueChanged<String> onChange;
  final bool compact;

  const _Segmented({
    required this.options,
    required this.selected,
    required this.onChange,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: BloomColors.card,
        border: Border.all(color: BloomColors.border, width: 1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          for (final o in options)
            Expanded(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => onChange(o),
                  borderRadius: BorderRadius.circular(9),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: selected == o
                          ? BloomColors.ink
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Text(
                      _shortLabel(o),
                      style: BloomTypography.geist(
                        fontSize: compact ? 11 : 12,
                        color: selected == o
                            ? Colors.white
                            : BloomColors.inkSoft,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _shortLabel(String o) => switch (o) {
        'Metade' => '½',
        'Julio' => 'Júlio',
        _ => o,
      };
}

