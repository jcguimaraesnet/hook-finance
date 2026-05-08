// Spec: docs/specs/state/persistence.md
//
// Login: usuário fornece o WEBHOOK_TOKEN. URL do backend é hardcoded em
// `lib/api/config.dart` via String.fromEnvironment.
// Checkbox opcional de biometria — quando marcado, próxima abertura pede
// biometria antes de auto-logar.

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
  late final TextEditingController _tokenCtrl;
  bool _busy = false;
  String? _error;
  bool _useBiometric = false;
  bool _biometricAvailable = false;

  @override
  void initState() {
    super.initState();
    final config = ref.read(authProvider).config;
    _tokenCtrl = TextEditingController(text: config.token);
    _useBiometric = config.biometricEnabled;
    _checkBiometric();
  }

  Future<void> _checkBiometric() async {
    final ok = await ref.read(authProvider.notifier).isBiometricAvailable();
    if (!mounted) return;
    setState(() {
      _biometricAvailable = ok;
      if (!ok) _useBiometric = false;
    });
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
    final result = await ref.read(authProvider.notifier).signIn(
          _tokenCtrl.text,
          useBiometric: _useBiometric,
        );
    if (!mounted) return;
    setState(() => _busy = false);
    if (!result.ok) {
      setState(() => _error = result.message ?? 'Falhou.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFFFFF6D6),
              theme.colorScheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const _BrandHero(),
                      const SizedBox(height: 28),
                      Card(
                        elevation: 0,
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Entrar',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _tokenCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Token',
                                  prefixIcon: Icon(Icons.key_outlined),
                                ),
                                obscureText: true,
                                autocorrect: false,
                                onFieldSubmitted: (_) => _submit(),
                                validator: (v) =>
                                    (v?.trim().isEmpty ?? true)
                                        ? 'Informe o token'
                                        : null,
                              ),
                              if (_biometricAvailable) ...[
                                const SizedBox(height: 8),
                                _BiometricToggle(
                                  value: _useBiometric,
                                  enabled: !_busy,
                                  onChanged: (v) =>
                                      setState(() => _useBiometric = v),
                                ),
                              ],
                              if (_error != null) ...[
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.errorContainer,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.error_outline,
                                          size: 18,
                                          color: theme.colorScheme.error),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          _error!,
                                          style: TextStyle(
                                            color: theme
                                                .colorScheme.onErrorContainer,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              const SizedBox(height: 20),
                              SizedBox(
                                height: 48,
                                child: FilledButton(
                                  onPressed: _busy ? null : _submit,
                                  style: FilledButton.styleFrom(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: _busy
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Text(
                                          'Entrar',
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Controle financeiro pessoal',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Logo + nome do app na parte superior da tela.
class _BrandHero extends StatelessWidget {
  const _BrandHero();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            color: const Color(0xFFF4D35E),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFF4D35E).withValues(alpha: 0.4),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Center(
            child: Text(
              '\$',
              style: TextStyle(
                fontSize: 56,
                fontWeight: FontWeight.w800,
                color: Color(0xFF2A1F00),
                height: 1,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Hook Finance',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }
}

class _BiometricToggle extends StatelessWidget {
  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  const _BiometricToggle({
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: enabled ? () => onChanged(!value) : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Checkbox(
              value: value,
              onChanged: enabled ? (v) => onChanged(v ?? false) : null,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.fingerprint,
              size: 18,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'Próximo login por biometria',
                style: theme.textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
