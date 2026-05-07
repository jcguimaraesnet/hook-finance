# hook-finance — Flutter app

Flutter (Android, iOS futuramente). Paridade com o PWA em [web/](../web). Regras de negócio espelham [docs/specs/rules/](../docs/specs/rules/) — qualquer mudança de comportamento começa lá.

## Setup

Pré-requisitos:
- Flutter 3.27+ stable (Dart 3.x). `flutter --version` para conferir; `flutter upgrade` se precisar.
- Android SDK (via Android Studio) para build de APK. **Não obrigatório** para `flutter test` ou `flutter analyze`.

```bash
cd app
flutter pub get
flutter analyze
flutter test
flutter run            # roda no device/emulador conectado
flutter run -d chrome  # roda como web (útil pra testar lógica sem device)
```

## Estrutura

```
app/lib/
├── main.dart              entry + initializeDateFormatting('pt_BR')
├── app.dart               MaterialApp + GoRouter + auth gate
├── core/                  ESPELHA web/src/core/ + docs/specs/rules
│   ├── types.dart         Row, Entry, Person, *Response
│   ├── constants.dart     kBucketOrder, kPersonOrder
│   ├── format/            money.dart, dates.dart
│   └── rules/             splitForPerson, bucketKey, diffCalculation, parcela
├── api/                   client.dart (dio), endpoints.dart, config.dart (prefs)
├── state/                 auth_provider.dart, data_providers.dart (Riverpod)
├── features/
│   ├── login/             LoginScreen (URL + token)
│   └── shell/             AppShell stub (Onda 4); Consulta/Detalhe/etc na Onda 5
└── theme/                 Material 3 inspirado na paleta amarela do PWA

app/test/core/             35 testes — espelho 1:1 dos testes do web/src/core
```

## Login

Diferente do PWA (que vive same-origin com `/api/proxy`), o Flutter precisa saber a URL do backend. A tela de login pede:

1. **URL da API** — `https://script.google.com/macros/s/.../exec` (Apps Script direto) OU `https://<seu-swa>.azurestaticapps.net/api/proxy` (proxy do PWA).
2. **Token** — o `WEBHOOK_TOKEN` configurado em `apps-script/shared/Setup.gs`.

Validação: bate `lastEntries(n=1)` antes de gravar. Persiste em `shared_preferences`.

## Próximos passos

- **Onda 5:** UI das 4 páginas (Consulta, Detalhe, Lançamento, Acerto) com paridade ao PWA. fl_chart para gráficos.
- **Ship Android:** `flutter build apk --release` + sideload via `adb install` ou transferência manual.
