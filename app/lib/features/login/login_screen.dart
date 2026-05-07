// Spec: docs/specs/state/persistence.md
//
// Login: usuário fornece o WEBHOOK_TOKEN. URL do backend é hardcoded em
// `lib/api/config.dart` via String.fromEnvironment.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../api/config.dart';
import '../../state/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _tokenCtrl;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final config = ref.read(authProvider).config;
    _tokenCtrl = TextEditingController(text: config.token);
  }

  @override
  void dispose() {
    _tokenCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final result = await ref.read(authProvider.notifier).signIn(_tokenCtrl.text);
    if (!mounted) return;
    setState(() => _busy = false);
    if (!result.ok) {
      setState(() => _error = result.message ?? 'Falhou.');
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
                    'Entrar',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Backend: $kApiBase',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _tokenCtrl,
                    decoration: const InputDecoration(labelText: 'Token'),
                    obscureText: true,
                    autocorrect: false,
                    onFieldSubmitted: (_) => _submit(),
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
