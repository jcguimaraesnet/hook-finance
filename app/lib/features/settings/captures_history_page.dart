// Spec: docs/specs/features/captura-notificacoes.md (Histórico de capturas)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format/dates.dart';
import '../../state/capture_history_provider.dart';
import '../../state/capture_log_entry.dart';
import '../../theme/bloom_colors.dart';
import '../../theme/bloom_typography.dart';
import '../../widgets/bloom/bloom_card.dart';
import '../../widgets/bloom/bloom_screen.dart';
import '../../widgets/bloom/screen_header.dart';

class CapturesHistoryPage extends ConsumerWidget {
  const CapturesHistoryPage({super.key});

  Future<void> _confirmClear(
      BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Limpar histórico?'),
        content: const Text(
            'Remove todas as capturas registradas. Não afeta a planilha.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Limpar'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(captureHistoryProvider.notifier).clear();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(captureHistoryProvider);
    final entries = async.valueOrNull ?? const <CaptureLogEntry>[];
    final loading = async.isLoading && !async.hasValue;

    return BloomScreen(
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          bottom: 24 + MediaQuery.of(context).padding.bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ScreenHeader(
              title: 'Histórico de capturas',
              showBack: true,
              trailing: entries.isEmpty
                  ? null
                  : IconButton(
                      onPressed: () => _confirmClear(context, ref),
                      icon: const Icon(Icons.delete_sweep_outlined),
                      tooltip: 'Limpar histórico',
                      color: BloomColors.inkSoft,
                    ),
            ),
            const SizedBox(height: 12),
            if (loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 60),
                child: Center(
                  child: CircularProgressIndicator(
                      color: BloomColors.violet),
                ),
              )
            else if (entries.isEmpty)
              const _EmptyState()
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: Column(
                  children: [
                    for (final e in entries) ...[
                      _CaptureCard(entry: e),
                      const SizedBox(height: 8),
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

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 40),
      child: BloomCard(
        padding: const EdgeInsets.all(22),
        child: Column(
          children: [
            const Icon(Icons.history_outlined,
                size: 36, color: BloomColors.muted),
            const SizedBox(height: 10),
            Text(
              'Nenhuma captura ainda. Ative no card acima e aguarde uma notificação.',
              textAlign: TextAlign.center,
              style: BloomTypography.geist(
                fontSize: 12.5,
                color: BloomColors.muted,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CaptureCard extends StatelessWidget {
  final CaptureLogEntry entry;
  const _CaptureCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final isOk = entry.status == 'ok';
    return BloomCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      borderRadius: BorderRadius.circular(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isOk ? Icons.check_circle : Icons.error_outline,
                size: 18,
                color: isOk ? BloomColors.good : BloomColors.bad,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  entry.title.isEmpty ? '(sem título)' : entry.title,
                  style: BloomTypography.geist(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: BloomColors.ink,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                relativeTime(entry.when),
                style: BloomTypography.geist(
                  fontSize: 11,
                  color: BloomColors.muted,
                ),
              ),
            ],
          ),
          if (entry.content.isNotEmpty) ...[
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(left: 26),
              child: Text(
                entry.content,
                style: BloomTypography.geist(
                  fontSize: 12,
                  color: BloomColors.muted,
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
          if (!isOk && entry.error != null) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 26),
              child: Text(
                entry.error!,
                style: BloomTypography.geist(
                  fontSize: 11.5,
                  color: BloomColors.bad,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
