import 'package:flutter_test/flutter_test.dart';
import 'package:hook_finance/core/rules/parcela.dart';

void main() {
  group('parcelaTotal', () {
    test('retorna 1 para vazio/null', () {
      expect(parcelaTotal(''), 1);
      expect(parcelaTotal(null), 1);
    });

    test("extrai N de '1/N'", () {
      expect(parcelaTotal('1/3'), 3);
      expect(parcelaTotal('1/12'), 12);
    });

    test('formato legado (número solo) também funciona', () {
      expect(parcelaTotal('3'), 3);
      expect(parcelaTotal('12'), 12);
    });

    test('formato inválido cai em 1 (defensivo)', () {
      expect(parcelaTotal('3/'), 1);
      expect(parcelaTotal('3/0'), 1);
      expect(parcelaTotal('abc'), 1);
    });
  });

  group('isParcelado', () {
    test('vazio/null/whitespace => false', () {
      expect(isParcelado(''), false);
      expect(isParcelado(null), false);
      expect(isParcelado('   '), false);
    });

    test('string com conteúdo => true', () {
      expect(isParcelado('1/3'), true);
      expect(isParcelado('3'), true);
    });
  });
}
