import 'package:flutter/material.dart';

import '../core/app_config.dart';
import '../core/app_session.dart';
import '../core/app_theme.dart';
import '../widgets/common_widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    await AppScope.of(context).login(_emailController.text, _passwordController.text);
  }

  @override
  Widget build(BuildContext context) {
    final session = AppScope.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(28, 34, 28, 30),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Align(child: AppLogo(size: 68)),
                        const SizedBox(height: 22),
                        Text(AppConfig.appName, textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineMedium),
                        const SizedBox(height: 6),
                        const Text(AppConfig.institutionName, textAlign: TextAlign.center, style: TextStyle(color: AppColors.muted)),
                        const SizedBox(height: 30),
                        Text('Bienvenido', style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 6),
                        const Text('Ingresa con tus credenciales institucionales.', style: TextStyle(color: AppColors.muted)),
                        const SizedBox(height: 22),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.email],
                          decoration: const InputDecoration(labelText: 'Correo institucional', prefixIcon: Icon(Icons.alternate_email_rounded)),
                          validator: (value) {
                            final email = value?.trim() ?? '';
                            if (email.isEmpty) return 'Ingresa tu correo institucional.';
                            if (!email.contains('@')) return 'Ingresa un correo válido.';
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscure,
                          textInputAction: TextInputAction.done,
                          autofillHints: const [AutofillHints.password],
                          onFieldSubmitted: (_) => _submit(),
                          decoration: InputDecoration(
                            labelText: 'Contraseña',
                            prefixIcon: const Icon(Icons.lock_outline_rounded),
                            suffixIcon: IconButton(
                              tooltip: _obscure ? 'Mostrar contraseña' : 'Ocultar contraseña',
                              onPressed: () => setState(() => _obscure = !_obscure),
                              icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                            ),
                          ),
                          validator: (value) => (value?.length ?? 0) < 8 ? 'La contraseña debe tener al menos 8 caracteres.' : null,
                        ),
                        if (session.errorMessage != null) ...[
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: AppColors.danger.withValues(alpha: .08), borderRadius: BorderRadius.circular(12)),
                            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              const Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 20),
                              const SizedBox(width: 10),
                              Expanded(child: Text(session.errorMessage!, style: const TextStyle(color: AppColors.danger))),
                            ]),
                          ),
                        ],
                        const SizedBox(height: 22),
                        FilledButton.icon(
                          onPressed: session.isSubmitting ? null : _submit,
                          icon: session.isSubmitting
                              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.login_rounded),
                          label: Text(session.isSubmitting ? 'Validando…' : 'Iniciar sesión'),
                        ),
                        const SizedBox(height: 18),
                        const Row(children: [Expanded(child: Divider()), Padding(padding: EdgeInsets.symmetric(horizontal: 10), child: Text('ACCESO SEGURO', style: TextStyle(fontSize: 11, color: AppColors.muted, letterSpacing: 1))), Expanded(child: Divider())]),
                        const SizedBox(height: 16),
                        const Text('Tu sesión se protege mediante un token cifrado en el dispositivo.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: AppColors.muted)),
                      ],
                    ),
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

