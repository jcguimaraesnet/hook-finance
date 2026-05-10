// Spec: docs/specs/state/persistence.md
//
// Login: usuário fornece o WEBHOOK_TOKEN. URL do backend é hardcoded em
// `lib/api/config.dart` via String.fromEnvironment.
// Switch opcional de biometria — quando ativo, próxima abertura pede
// biometria antes de auto-logar.

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../state/auth_provider.dart';
import '../../theme/bloom_colors.dart';
import '../../theme/bloom_typography.dart';
import '../../widgets/bloom/bloom_logo.dart';
import '../../widgets/bloom/bloom_shapes.dart';

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
    if (kIsWeb) {
      setState(() {
        _biometricAvailable = false;
        _useBiometric = false;
      });
      return;
    }
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
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: BloomColors.screenGradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Stack(
            children: [
              const Positioned.fill(child: BloomShapes()),
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 28, vertical: 24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const _BrandHero(),
                          const SizedBox(height: 36),
                          _LoginCard(
                            tokenCtrl: _tokenCtrl,
                            busy: _busy,
                            error: _error,
                            biometricAvailable: _biometricAvailable,
                            useBiometric: _useBiometric,
                            onBiometricChanged: (v) =>
                                setState(() => _useBiometric = v),
                            onSubmit: _submit,
                          ),
                          const SizedBox(height: 18),
                          Text(
                            'seguro com 256-bit',
                            textAlign: TextAlign.center,
                            style: BloomTypography.mono(
                              fontSize: 11.5,
                              color: BloomColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BrandHero extends StatelessWidget {
  const _BrandHero();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const BloomLogo(size: 72),
        const SizedBox(height: 18),
        Text(
          'Hook Finance',
          textAlign: TextAlign.center,
          style: BloomTypography.display(
            fontSize: 34,
            letterSpacing: -0.8,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Controle financeiro para casais',
          textAlign: TextAlign.center,
          style: BloomTypography.geist(
            fontSize: 13,
            color: BloomColors.muted,
          ),
        ),
      ],
    );
  }
}

class _LoginCard extends StatelessWidget {
  final TextEditingController tokenCtrl;
  final bool busy;
  final String? error;
  final bool biometricAvailable;
  final bool useBiometric;
  final ValueChanged<bool> onBiometricChanged;
  final VoidCallback onSubmit;

  const _LoginCard({
    required this.tokenCtrl,
    required this.busy,
    required this.error,
    required this.biometricAvailable,
    required this.useBiometric,
    required this.onBiometricChanged,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: BloomColors.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: BloomColors.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: BloomColors.violet.withValues(alpha: 0.10),
            blurRadius: 40,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Bem-vindo',
              style: BloomTypography.display(
                  fontSize: 20, letterSpacing: -0.4)),
          const SizedBox(height: 2),
          Text(
            'Use seu token para entrar',
            style: BloomTypography.geist(
                fontSize: 12, color: BloomColors.muted),
          ),
          const SizedBox(height: 16),
          Text(
            'TOKEN',
            style: BloomTypography.kicker(),
          ),
          const SizedBox(height: 6),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: BloomColors.bg3,
              border: Border.all(color: BloomColors.border, width: 1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(Icons.vpn_key_outlined,
                    size: 18, color: BloomColors.violet),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: tokenCtrl,
                    obscureText: true,
                    autocorrect: false,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      filled: false,
                      isDense: true,
                      contentPadding:
                          EdgeInsets.symmetric(vertical: 14),
                      hintText: '••••••••••••',
                    ),
                    style: BloomTypography.mono(
                      fontSize: 14,
                      letterSpacing: 1,
                    ),
                    onFieldSubmitted: (_) => onSubmit(),
                    validator: (v) => (v?.trim().isEmpty ?? true)
                        ? 'Informe o token'
                        : null,
                  ),
                ),
              ],
            ),
          ),
          if (biometricAvailable) ...[
            const SizedBox(height: 14),
            _BiometricToggle(
              value: useBiometric,
              enabled: !busy,
              onChanged: onBiometricChanged,
            ),
          ],
          if (error != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: BloomColors.bad.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline,
                      size: 18, color: BloomColors.bad),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      error!,
                      style: BloomTypography.geist(
                          fontSize: 13, color: BloomColors.bad),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 18),
          _GradientButton(
            busy: busy,
            onPressed: onSubmit,
          ),
        ],
      ),
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
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: enabled ? () => onChanged(!value) : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            _PillSwitch(value: value, onChanged: enabled ? onChanged : null),
            const SizedBox(width: 10),
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: BloomTypography.geist(
                    fontSize: 12.5,
                    color: BloomColors.inkSoft,
                  ),
                  children: const [
                    TextSpan(text: 'Próximo login por '),
                    TextSpan(
                      text: 'biometria',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
            const Icon(Icons.fingerprint,
                size: 18, color: BloomColors.muted),
          ],
        ),
      ),
    );
  }
}

class _PillSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;

  const _PillSwitch({required this.value, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onChanged == null ? null : () => onChanged!(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 38,
        height: 22,
        decoration: BoxDecoration(
          color: value
              ? BloomColors.violet
              : const Color(0xFFD9D6F0),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Stack(
          children: [
            AnimatedPositioned(
              duration: const Duration(milliseconds: 180),
              top: 2,
              left: value ? 18 : 2,
              child: Container(
                width: 18,
                height: 18,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x26000000),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GradientButton extends StatelessWidget {
  final bool busy;
  final VoidCallback onPressed;

  const _GradientButton({required this.busy, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: busy ? null : onPressed,
        child: Container(
          height: 50,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [BloomColors.violet, BloomColors.sky],
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: BloomColors.violet.withValues(alpha: 0.33),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: busy
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(
                  'Entrar →',
                  style: BloomTypography.display(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.2,
                  ),
                ),
        ),
      ),
    );
  }
}
