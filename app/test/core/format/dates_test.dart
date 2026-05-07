import 'package:flutter_test/flutter_test.dart';
import 'package:hook_finance/core/format/dates.dart';

void main() {
  group('parseBrDate', () {
    test('parseia DD/MM/YYYY', () {
      final d = parseBrDate('06/05/2026');
      expect(d.year, 2026);
      expect(d.month, 5);
      expect(d.day, 6);
    });

    test('retorna epoch zero para formato inválido', () {
      expect(parseBrDate(''), DateTime.fromMillisecondsSinceEpoch(0));
      expect(parseBrDate('2026-05-06'), DateTime.fromMillisecondsSinceEpoch(0));
    });
  });

  group('monthYearLabel', () {
    test('converte para nome do mês em pt-BR', () {
      expect(monthYearLabel('06/05/2026'), 'maio de 2026');
      expect(monthYearLabel('01/01/2026'), 'janeiro de 2026');
      expect(monthYearLabel('31/12/2026'), 'dezembro de 2026');
    });

    test("vazio retorna ''", () {
      expect(monthYearLabel(''), '');
      expect(monthYearLabel(null), '');
    });
  });

  group('brDateToMMYYYY', () {
    test('extrai MM/YYYY de DD/MM/YYYY', () {
      expect(brDateToMMYYYY('06/05/2026'), '05/2026');
      expect(brDateToMMYYYY('31/12/2025'), '12/2025');
    });

    test('formato inválido retorna a string original', () {
      expect(brDateToMMYYYY(''), '');
      expect(brDateToMMYYYY('abc'), 'abc');
    });
  });
}
