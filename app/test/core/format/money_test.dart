import 'package:flutter_test/flutter_test.dart';
import 'package:hook_finance/core/format/money.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('pt_BR');
  });

  group('formatMoney', () {
    test('formata número pt-BR com 2 casas', () {
      expect(formatMoney(1234.5), matches(RegExp(r'^1\.234,50$')));
      expect(formatMoney(0), '0,00');
    });
  });

  group('moneyK', () {
    test('< 1000 formata locale', () {
      expect(moneyK(500), '500');
      expect(moneyK(0), '0');
      expect(moneyK(999), '999');
    });

    test('>= 1000 abrevia em k', () {
      expect(moneyK(1000), '1k');
      expect(moneyK(1500), '1,5k');
      expect(moneyK(20000), '20k');
      expect(moneyK(1234), '1,2k');
    });

    test('NaN/null retorna ""', () {
      expect(moneyK(double.nan), '');
      expect(moneyK(null), '');
    });

    test('preserva sinal negativo', () {
      expect(moneyK(-1500), '-1,5k');
    });
  });
}
