// Spec: docs/specs/rules/parcela-format.md
// Mudanças aqui DEVEM começar pela spec.

/// Extrai o total de parcelas a partir de "X/Y" (ou número legado).
/// Vazio/null/inválido -> 1.
int parcelaTotal(Object? p) {
  if (p == null) return 1;
  final s = p.toString().trim();
  if (s.isEmpty) return 1;
  if (s.contains('/')) {
    final parts = s.split('/');
    if (parts.length < 2) return 1;
    return int.tryParse(parts[1]) is int && (int.tryParse(parts[1]) ?? 0) > 0
        ? int.parse(parts[1])
        : 1;
  }
  final n = int.tryParse(s) ?? 0;
  return n > 0 ? n : 1;
}

bool isParcelado(Object? p) {
  if (p == null) return false;
  return p.toString().trim().isNotEmpty;
}
