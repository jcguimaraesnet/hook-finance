// PathUrlStrategy → URLs limpas no web (`/inicio` em vez de `/#/inicio`).

import 'package:flutter_web_plugins/url_strategy.dart';

void configureUrlStrategy() {
  usePathUrlStrategy();
}
