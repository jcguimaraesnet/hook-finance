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
│   ├── login/             LoginScreen (só token; URL hardcoded)
│   ├── shell/             AppShell com NavigationBar e 4 páginas
│   ├── consulta/          ConsultaPage (mês/categoria/pessoal/histórico)
│   ├── detalhe/           DetalhePage (accordions por pessoa)
│   ├── lancamento/        LancamentoPage + EditDialog
│   └── acerto/            AcertoPage
└── theme/                 Material 3 inspirado na paleta amarela do PWA

app/test/core/             35 testes — espelho 1:1 dos testes do web/src/core
```

## Login

A URL do backend é compilada no app (constante `kApiBase` em [lib/api/config.dart](lib/api/config.dart) via `String.fromEnvironment`). Por padrão aponta para o `/api/proxy` do Azure SWA. A tela de login pede só o **token** (`WEBHOOK_TOKEN` configurado em `apps-script/shared/Setup.gs`).

Validação: bate `lastEntries(n=1)` antes de gravar. Token persiste em `shared_preferences`.

### Override da URL em build

Para apontar para outro backend (dev local, staging) sem editar código:

```bash
flutter build apk --release --dart-define=API_BASE=https://outra/api/proxy
flutter run --dart-define=API_BASE=http://localhost:7071/api/proxy
```

## Ship Android

```bash
flutter build apk --release
# APK em build/app/outputs/flutter-apk/app-release.apk (~50 MB, debug-signed)
```

Sideload via `adb install` (USB debugging) ou GitHub Release pra baixar no celular.
