import 'package:flutter_test/flutter_test.dart';
import 'package:hook_finance/state/capture_log_entry.dart';

void main() {
  group('CaptureLogEntry.toJson', () {
    test('serializa todos os campos', () {
      const e = CaptureLogEntry(
        ts: 1715441234567,
        package: 'com.nu.production',
        title: 'Compra aprovada',
        content: 'R\$ 42,50 em MERCADO',
        status: 'ok',
        error: null,
      );
      expect(e.toJson(), {
        'ts': 1715441234567,
        'package': 'com.nu.production',
        'title': 'Compra aprovada',
        'content': 'R\$ 42,50 em MERCADO',
        'status': 'ok',
        'error': null,
      });
    });

    test('inclui error quando presente', () {
      const e = CaptureLogEntry(
        ts: 1,
        package: 'p',
        title: 't',
        content: 'c',
        status: 'error',
        error: 'Backend: 500',
      );
      expect(e.toJson()['error'], 'Backend: 500');
    });
  });

  group('CaptureLogEntry.fromJson', () {
    test('parseia JSON completo', () {
      final e = CaptureLogEntry.fromJson({
        'ts': 1715441234567,
        'package': 'com.nu.production',
        'title': 'Compra aprovada',
        'content': 'corpo',
        'status': 'ok',
        'error': null,
      });
      expect(e.ts, 1715441234567);
      expect(e.package, 'com.nu.production');
      expect(e.title, 'Compra aprovada');
      expect(e.content, 'corpo');
      expect(e.status, 'ok');
      expect(e.error, null);
    });

    test('defaults para campos ausentes', () {
      final e = CaptureLogEntry.fromJson(<String, dynamic>{});
      expect(e.ts, 0);
      expect(e.package, '');
      expect(e.title, '');
      expect(e.content, '');
      expect(e.status, 'ok');
      expect(e.error, null);
    });
  });

  group('CaptureLogEntry.when', () {
    test('converte ts para DateTime', () {
      const e = CaptureLogEntry(
        ts: 1715441234567,
        package: 'p',
        title: 't',
        content: 'c',
        status: 'ok',
      );
      expect(e.when, DateTime.fromMillisecondsSinceEpoch(1715441234567));
    });
  });
}
