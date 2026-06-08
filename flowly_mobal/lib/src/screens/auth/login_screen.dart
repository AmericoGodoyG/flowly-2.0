import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:meu_app/src/app/flowly_theme.dart';
import 'package:meu_app/src/models/auth_result.dart';
import 'package:meu_app/src/screens/auth/face_auth_screen.dart';
import 'package:meu_app/src/services/auth_service.dart';
import 'package:meu_app/src/widgets/auth_background.dart';
import 'package:meu_app/src/widgets/flowly_card.dart';
import 'package:meu_app/src/widgets/validated_text_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.initialEmail});

  final String? initialEmail;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();

  bool _obscurePassword = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialEmail != null && widget.initialEmail!.isNotEmpty) {
      _emailController.text = widget.initialEmail!;
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _isSubmitting) {
      return;
    }

    setState(() => _isSubmitting = true);
    final messenger = ScaffoldMessenger.of(context);

    final result = await _authService.login(
      email: _emailController.text.trim(),
      senha: _passwordController.text,
    );

    if (!mounted) {
      return;
    }

    setState(() => _isSubmitting = false);

    if (result.requiresFaceVerification || result.requiresFaceEnrollmentOffer) {
      await Navigator.of(context).push<AuthResult>(
        MaterialPageRoute<AuthResult>(
          builder: (context) => FaceAuthScreen(
            mode: result.requiresFaceVerification
                ? FaceAuthMode.verify
                : FaceAuthMode.enroll,
            faceSessionToken: result.faceSessionToken ?? '',
            userName: result.name ?? 'usuário',
            onCancel: () => Navigator.pop(context),
            onSkip: result.requiresFaceEnrollmentOffer ? () {} : null,
            onSuccess: (faceResult) => Navigator.pop(context, faceResult),
          ),
        ),
      ).then((faceResult) async {
        if (!mounted || faceResult == null) {
          return;
        }

        messenger.hideCurrentSnackBar();
        messenger.showSnackBar(
          SnackBar(
            content: Text(faceResult.message),
            backgroundColor: faceResult.success
                ? const Color(0xFF0D9C6E)
                : const Color(0xFFC62828),
          ),
        );

        if (faceResult.success && faceResult.token != null) {
          await _authService.persistAuthSession(
            token: faceResult.token!,
            email: _emailController.text.trim(),
            userType: faceResult.userType ?? 'user',
            userId: faceResult.userId,
            name: faceResult.name,
            fotoPerfil: faceResult.userPhoto,
          );
          if (mounted) {
            context.go('/dashboard');
          }
        }
      });
      return;
    }

    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(result.message),
        backgroundColor: result.success
            ? const Color(0xFF0D9C6E)
            : const Color(0xFFC62828),
      ),
    );

    if (result.success) {
      context.go('/dashboard');
      return;
    }

    if (result.requiresVerification) {
      final String encodedEmail = Uri.encodeComponent(
        _emailController.text.trim(),
      );
      context.go('/verify-email?email=$encodedEmail');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AuthBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: FlowlyCard(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Image.asset(
                          'assets/images/flowly_logo.png',
                          height: 150,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Bem-vindo de volta!',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: flowlyText,
                              ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Entre na sua conta para continuar no Flowly',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 20),
                        ValidatedTextField(
                          controller: _emailController,
                          label: 'E-mail',
                          hint: 'seu.email@exemplo.com',
                          prefixIcon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          validator: (String? value) {
                            final String email = (value ?? '').trim();
                            if (email.isEmpty) {
                              return 'Informe seu e-mail.';
                            }
                            if (!email.contains('@')) {
                              return 'E-mail inválido.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        ValidatedTextField(
                          controller: _passwordController,
                          label: 'Senha',
                          hint: 'Digite sua senha',
                          prefixIcon: Icons.lock_outlined,
                          obscureText: _obscurePassword,
                          suffixIcon: _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          onSuffixIconPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                          validator: (String? value) {
                            if ((value ?? '').isEmpty) {
                              return 'Informe sua senha.';
                            }
                            if ((value ?? '').length < 6) {
                              return 'A senha deve ter no mínimo 6 caracteres.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 18),
                        FilledButton(
                          onPressed: _isSubmitting ? null : _submit,
                          style: FilledButton.styleFrom(
                            backgroundColor: flowlySecondary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: _isSubmitting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Entrar'),
                        ),
                        const SizedBox(height: 10),
                        OutlinedButton(
                          onPressed: _isSubmitting
                              ? null
                              : () => context.go('/register'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: flowlySecondary,
                            side: const BorderSide(color: flowlySecondary),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text('Criar conta'),
                        ),
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
