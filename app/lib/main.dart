import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'app.dart';
import 'url_strategy_stub.dart'
    if (dart.library.html) 'url_strategy_web.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  configureUrlStrategy();
  await initializeDateFormatting('pt_BR');
  runApp(const ProviderScope(child: HookFinanceApp()));
}
