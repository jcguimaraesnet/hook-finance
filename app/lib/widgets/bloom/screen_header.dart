// Header de tela — kicker (uppercase muted) + título Bricolage + slot direito p/ MonthSelector.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/bloom_colors.dart';
import '../../theme/bloom_typography.dart';

class ScreenHeader extends StatelessWidget {
  final String? kicker;
  final String title;
  final Widget? trailing;
  final bool showBack;
  final VoidCallback? onBack;

  const ScreenHeader({
    super.key,
    this.kicker,
    required this.title,
    this.trailing,
    this.showBack = false,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 10, 22, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showBack) ...[
            _BackButton(
              onTap: onBack ??
                  () {
                    final router = GoRouter.of(context);
                    if (router.canPop()) {
                      router.pop();
                    }
                  },
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (kicker != null)
                  Text(
                    kicker!.toUpperCase(),
                    style: BloomTypography.kicker(),
                  ),
                const SizedBox(height: 2),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: BloomTypography.display(
                          fontSize: 28,
                          letterSpacing: -0.6,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (trailing != null) ...[
                      const SizedBox(width: 10),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: trailing!,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  final VoidCallback onTap;
  const _BackButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: BloomColors.card,
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: BloomColors.border, width: 1),
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.chevron_left,
                color: BloomColors.ink, size: 20),
          ),
        ),
      ),
    );
  }
}
