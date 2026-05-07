// Spec: docs/specs/state/persistence.md
//
// Login: usuário fornece a base URL do backend (Apps Script direto OU /api/proxy
// do PWA hospedado) e o WEBHOOK_TOKEN. Validamos batendo lastEntries(n=1).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../state/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _apiBaseCtrl;
  late final TextEditingController _tokenCtrl;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final config = ref.read(authProvider).config;
    _apiBaseCtrl = TextEditingController(text: config.apiBase);
    _tokenCtrl = TextEditingController(text: config.token);
  }

  @override
  void dispose() {
    _apiBaseCtrl.dispose();
    _tokenCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final ok = await ref
        .read(authProvider.notifier)
        .signIn(_apiBaseCtrl.text, _tokenCtrl.text);
    if (!mounted) return;
    setState(() => _busy = false);
    if (!ok) {
      setState(() => _error = 'Não autorizou. Confira URL e token.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('hook-finance')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Configurar acesso',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'URL do backend (Apps Script ou /api/proxy do PWA) + token.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _apiBaseCtrl,
                    decoration: const InputDecoration(
                      labelText: 'URL da API',
                      hintText: 'https://… (termina em /exec ou /api/proxy)',
                    ),
                    keyboardType: TextInputType.url,
                    autocorrect: false,
                    validator: (v) {
                      final s = v?.trim() ?? '';
                      if (s.isEmpty) return 'Informe a URL';
                      if (!s.startsWith('http')) return 'URL inválida';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _tokenCtrl,
                    decoration: const InputDecoration(labelText: 'Token'),
                    obscureText: true,
                    autocorrect: false,
                    validator: (v) =>
                        (v?.trim().isEmpty ?? true) ? 'Informe o token' : null,
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: _busy ? null : _submit,
                    child: Text(_busy ? 'Validando…' : 'Entrar'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
