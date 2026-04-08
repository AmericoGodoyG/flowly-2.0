import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:meu_app/src/app/flowly_theme.dart';
import 'package:meu_app/src/services/auth_service.dart';
import 'package:meu_app/src/widgets/auth_background.dart';
import 'package:meu_app/src/widgets/flowly_button.dart';
import 'package:meu_app/src/widgets/flowly_card.dart';

class VerifyEmailScreen extends StatefulWidget {
  final String email;

  const VerifyEmailScreen({required this.email, super.key});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  final TextEditingController _codeController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isSubmitting = false;
  bool _isResending = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _submitCode() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      _showMessage('Informe o código de verificação', isError: true);
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final result = await _authService.verifyCode(
        email: widget.email,
        code: code,
      );

      if (!mounted) return;

      if (result.success) {
        _showMessage('Email verificado com sucesso!', isError: false);
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) {
          context.go('/login');
        }
      } else {
        _showMessage(result.message, isError: true);
      }
    } catch (e) {
      _showMessage('Erro ao verificar código: ${e.toString()}', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _resendCode() async {
    setState(() => _isResending = true);

    try {
      final result = await _authService.resendCode(email: widget.email);

      if (!mounted) return;

      if (result.success) {
        _showMessage('Código reenviado para seu email!', isError: false);
      } else {
        _showMessage(result.message, isError: true);
      }
    } catch (e) {
      _showMessage('Erro ao reenviar código: ${e.toString()}', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isResending = false);
      }
    }
  }

  void _showMessage(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? const Color(0xFFC62828)
            : const Color(0xFF0D9C6E),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isSmallScreen = MediaQuery.of(context).size.width < 600;
    final EdgeInsets padding = isSmallScreen
        ? const EdgeInsets.symmetric(horizontal: 20, vertical: 24)
        : const EdgeInsets.symmetric(horizontal: 40, vertical: 40);

    return Scaffold(
      body: AuthBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: padding,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: FlowlyCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      // Header Icon
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: flowlyPrimary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.mail_outlined,
                          color: flowlyPrimary,
                          size: 48,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Title
                      Text(
                        'Verificar email',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              color: flowlyText,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 8),
                      // Description
                      Text(
                        'Enviamos um código de verificação para\n${widget.email}',
                        textAlign: TextAlign.center,
                        style: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.copyWith(color: flowlyText),
                      ),
                      const SizedBox(height: 24),
                      // Code Input Field
                      TextFormField(
                        controller: _codeController,
                        decoration: InputDecoration(
                          labelText: 'Código de verificação',
                          hintText: 'Ex: 123456',
                          prefixIcon: const Icon(Icons.lock_outline),
                          helperText: 'Verifique sua caixa de entrada e spam',
                        ),
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              letterSpacing: 2.0,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 20),
                      // Verify Button
                      FlowlyButton(
                        onPressed: _isSubmitting ? () {} : () => _submitCode(),
                        label: _isSubmitting ? 'Verificando...' : 'Verificar',
                        isLoading: _isSubmitting,
                      ),
                      const SizedBox(height: 12),
                      // Resend Button
                      OutlinedButton.icon(
                        onPressed: _isResending ? null : _resendCode,
                        icon: const Icon(Icons.refresh),
                        label: Text(
                          _isResending ? 'Reenviando...' : 'Reenviar código',
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Back to Login
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Voltar para ',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          TextButton(
                            onPressed: () => context.go('/login'),
                            child: const Text('login'),
                          ),
                        ],
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
