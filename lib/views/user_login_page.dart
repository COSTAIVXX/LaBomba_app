import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/google_auth_provider.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';

class UserLoginPage extends StatefulWidget {
  const UserLoginPage({super.key});

  @override
  State<UserLoginPage> createState() => _UserLoginPageState();
}

class _UserLoginPageState extends State<UserLoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isSubmitting = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submitEmailLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      final authService = context.read<AuthService>();
      final result = await authService.signInWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );

      if (!mounted) return;
      if (result == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Credenciais inválidas ou serviço indisponível.')),
        );
        return;
      }

      // Ensure Firebase session is active before navigating: require a valid ID token
      try {
        final token = await authService.getIdToken(forceRefresh: true);
        if (token == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Falha ao validar sessão. Tente novamente.')),
          );
          return;
        }
      } catch (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Falha ao validar sessão. Tente novamente.')),
        );
        return;
      }

      Navigator.pushNamedAndRemoveUntil(context, '/landing', (route) => false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível entrar agora: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _submitGoogleLogin() async {
    setState(() => _isSubmitting = true);
    try {
      final googleProvider = context.read<GoogleAuthProvider>();
      final data = await googleProvider.signInWithGoogle();
      if (!mounted) return;
      if (data == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Login do Google cancelado.')),
        );
        return;
      }

      Navigator.pushNamedAndRemoveUntil(context, '/landing', (route) => false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Google Sign-In indisponível no momento. Tente novamente.')),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final blueGlow = AppTheme.primary.withValues(alpha: 0.12);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F9FF),
      appBar: AppBar(
        title: const Text('Entrar'),
        backgroundColor: Colors.transparent,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFFEAF3FF),
              const Color(0xFFF7FAFF),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: AppTheme.primary.withValues(alpha: 0.18)),
                    boxShadow: [
                      BoxShadow(
                        color: blueGlow,
                        blurRadius: 32,
                        offset: const Offset(0, 16),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 76,
                          height: 76,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [AppTheme.primary, AppTheme.primaryLight],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primary.withValues(alpha: 0.24),
                                blurRadius: 18,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.local_fire_department_rounded, size: 36, color: Colors.white),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Bem-vindo de volta',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF102A43),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Acesse sua conta do La Bomba',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Color(0xFF475569), fontSize: 15),
                        ),
                        const SizedBox(height: 24),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          style: const TextStyle(color: Color(0xFF0F172A)),
                          decoration: InputDecoration(
                            labelText: 'E-mail',
                            hintText: 'seu@email.com',
                            filled: true,
                            fillColor: const Color(0xFFF8FBFF),
                            prefixIcon: const Icon(Icons.email_outlined, color: AppTheme.primary),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: AppTheme.primary.withValues(alpha: 0.2)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: AppTheme.primary.withValues(alpha: 0.2)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: AppTheme.primary, width: 1.6),
                            ),
                            labelStyle: const TextStyle(color: Color(0xFF1E3A8A)),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Informe seu e-mail.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          style: const TextStyle(color: Color(0xFF0F172A)),
                          decoration: InputDecoration(
                            labelText: 'Senha',
                            filled: true,
                            fillColor: const Color(0xFFF8FBFF),
                            prefixIcon: const Icon(Icons.lock_outline, color: AppTheme.primary),
                            suffixIcon: IconButton(
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                              icon: Icon(
                                _obscurePassword ? Icons.visibility : Icons.visibility_off,
                                color: AppTheme.primary,
                              ),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: AppTheme.primary.withValues(alpha: 0.2)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: AppTheme.primary.withValues(alpha: 0.2)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: AppTheme.primary, width: 1.6),
                            ),
                            labelStyle: const TextStyle(color: Color(0xFF1E3A8A)),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Informe sua senha.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        FilledButton.icon(
                          onPressed: _isSubmitting ? null : _submitEmailLogin,
                          icon: const Icon(Icons.login_rounded),
                          label: const Text('Entrar com e-mail'),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: _isSubmitting ? null : _submitGoogleLogin,
                          icon: const Icon(Icons.g_mobiledata_rounded, color: AppTheme.primary),
                          label: const Text('Continuar com Google', style: TextStyle(color: Color(0xFF0F172A))),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: const BorderSide(color: AppTheme.primary, width: 1.4),
                            backgroundColor: const Color(0xFFF8FBFF),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: const [
                            Expanded(child: Divider(color: Color(0xFFBFDBFE))),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              child: Text('ou', style: TextStyle(color: Color(0xFF475569), fontWeight: FontWeight.w700)),
                            ),
                            Expanded(child: Divider(color: Color(0xFFBFDBFE))),
                          ],
                        ),
                        const SizedBox(height: 18),
                        TextButton(
                          onPressed: () => Navigator.pushNamed(context, '/register'),
                          child: const Text(
                            'Criar conta',
                            style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w800),
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
      ),
    );
  }
}
