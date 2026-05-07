// Spec: docs/specs/state/persistence.md
// Equivalente ao sessionStorage `hook-finance-diff-{Person}` do PWA.
// Em Flutter não há sessionStorage; usamos state em memória que reseta ao
// reabrir o app (comportamento equivalente ao "fechar a aba").

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/types.dart';

final diffVisibleProvider = StateProvider.family<bool, Person>((_, _) => true);
