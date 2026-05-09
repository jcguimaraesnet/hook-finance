// Estado do bottom-nav: aba ativa + pessoa selecionada (visão pessoal). Sessão.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/types.dart';
import '../widgets/bloom/bloom_bottom_nav.dart';

final activeTabProvider =
    StateProvider<BloomTab>((_) => BloomTab.inicio);

/// Pessoa selecionada na visão pessoal (Início, Detalhe). Sessão.
final selectedPersonProvider = StateProvider<Person>((_) => Person.julio);
