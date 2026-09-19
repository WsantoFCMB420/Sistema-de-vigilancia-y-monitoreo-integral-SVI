import 'dart:async'; // Para TimeoutException
import 'dart:convert';
import 'dart:io'; // Para SocketException
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../main.dart'; // SessionService y AppRoutes

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  static const Color _bgColor = Color(0xFFDDE8F5);
  static const Color _primaryBlue = Color(0xFF1A5DC8);
  static const Color _lightBlue = Color(0xFFEEF4FF);
  static const Color _cardColor = Colors.white;
  static const Color _labelColor = Color(0xFF6B7A99);
  static const Color _textColor = Color(0xFF1A2340);
  static const Color _hintColor = Color(0xFFADB8CC);
  static const Color _borderColor = Color(0xFFD0DAEA);

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ── LÓGICA DE LOGIN ───────────────────────────────────────────
  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final response = await http
          .post(
            Uri.parse('https://humberto.alwaysdata.net/api/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'email': _emailController.text.trim(),
              'password': _passwordController.text,
            }),
          )
          .timeout(const Duration(seconds: 10));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        await SessionService.saveSession(
          token: data['token'],
          name: data['user']['name'],
          email: data['user']['email'],
          role: data['user']['role'] ?? 'viewer',
          userId: data['user']['id'] ?? 0,
        );

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('¡Bienvenido, ${data['user']['name']}!'),
            backgroundColor: _primaryBlue,
          ),
        );
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                data['error'] ?? data['message'] ?? 'Credenciales incorrectas'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } on SocketException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sin conexión. Verifica tu red o el servidor.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } on TimeoutException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tiempo de espera agotado. Intenta de nuevo.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error inesperado al conectar con el servidor.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── RECUPERAR CONTRASEÑA ──────────────────────────────────────
  Future<void> _showForgotPasswordDialog() async {
    final emailCtrl = TextEditingController();
    return showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          bool loading = false;
          return AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text(
              'Recuperar contraseña',
              style: TextStyle(fontWeight: FontWeight.w700, color: _textColor),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Ingresa tu correo electrónico y te enviaremos un enlace para restablecer tu contraseña.',
                  style: TextStyle(fontSize: 13, color: _labelColor),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: 'nombre@ejemplo.com',
                    hintStyle: const TextStyle(color: _hintColor),
                    filled: true,
                    fillColor: _lightBlue,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: _borderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: _primaryBlue, width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                  ),
                ),
                if (loading) const SizedBox(height: 16),
                if (loading)
                  const CircularProgressIndicator(color: _primaryBlue),
              ],
            ),
            actions: [
              TextButton(
                onPressed: loading ? null : () => Navigator.pop(ctx),
                child: const Text('Cancelar',
                    style: TextStyle(color: _labelColor)),
              ),
              ElevatedButton(
                onPressed: loading
                    ? null
                    : () async {
                        final email = emailCtrl.text.trim();
                        if (email.isEmpty ||
                            !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email)) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Ingresa un correo válido'),
                              backgroundColor: Colors.redAccent,
                            ),
                          );
                          return;
                        }
                        setDialogState(() => loading = true);
                        try {
                          final res = await http
                              .post(
                                Uri.parse(
                                    'https://humberto.alwaysdata.net/api/forgot-password'),
                                headers: {'Content-Type': 'application/json'},
                                body: jsonEncode({'email': email}),
                              )
                              .timeout(const Duration(seconds: 10));

                          final data = jsonDecode(res.body);
                          if (res.statusCode == 200) {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  data['message'] ??
                                      'Correo enviado. Revisa tu bandeja de entrada.',
                                ),
                                backgroundColor: _primaryBlue,
                              ),
                            );
                          } else {
                            setDialogState(() => loading = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  data['message'] ??
                                      data['error'] ??
                                      'Error al enviar el correo',
                                ),
                                backgroundColor: Colors.redAccent,
                              ),
                            );
                          }
                        } catch (e) {
                          setDialogState(() => loading = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content:
                                  Text('No se pudo conectar con el servidor.'),
                              backgroundColor: Colors.redAccent,
                            ),
                          );
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryBlue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child:
                    const Text('Enviar', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  // ── BUILD ─────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildBrand(),
              const SizedBox(height: 32),
              _buildFormCard(),
              const SizedBox(height: 24),
              _buildBiometricOption(),
            ],
          ),
        ),
      ),
    );
  }

  // ── MARCA / LOGO ──────────────────────────────────────────────
  Widget _buildBrand() {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: _primaryBlue,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: _primaryBlue.withValues(alpha: 0.35),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child:
              const Icon(Icons.shield_rounded, color: Colors.white, size: 40),
        ),
        const SizedBox(height: 14),
        const Text(
          'Sentinel Surveillance',
          style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: _primaryBlue,
              letterSpacing: 0.2),
        ),
        const SizedBox(height: 6),
        const Text(
          'Protegiendo tu comunidad con inteligencia\ny vigilancia avanzada.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: _labelColor, height: 1.5),
        ),
      ],
    );
  }

  // ── TARJETA FORMULARIO ────────────────────────────────────────
  Widget _buildFormCard() {
    return Container(
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 24,
              offset: const Offset(0, 6)),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Bienvenido',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: _textColor)),
            const SizedBox(height: 4),
            const Text('Ingrese sus credenciales para continuar',
                style: TextStyle(fontSize: 13, color: _labelColor)),
            const SizedBox(height: 24),
            _buildLabel('CORREO ELECTRÓNICO'),
            const SizedBox(height: 6),
            _buildEmailField(),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildLabel('CONTRASEÑA'),
                GestureDetector(
                  onTap:
                      _showForgotPasswordDialog, // ← Ahora ejecuta la función
                  child: const Text('¿Olvidó su contraseña?',
                      style: TextStyle(
                          fontSize: 12,
                          color: _primaryBlue,
                          fontWeight: FontWeight.w500)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            _buildPasswordField(),
            const SizedBox(height: 28),
            _buildLoginButton(),
            const SizedBox(height: 20),
            _buildRegisterSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(text,
        style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: _labelColor,
            letterSpacing: 0.8));
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      style: const TextStyle(fontSize: 14, color: _textColor),
      decoration: _inputDecoration(
        hint: 'nombre@ejemplo.com',
        suffix: const Icon(Icons.email_outlined, size: 18, color: _hintColor),
      ),
      validator: (v) {
        if (v == null || v.isEmpty) return 'Ingrese su correo';
        if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v))
          return 'Correo no válido';
        return null;
      },
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      style: const TextStyle(fontSize: 14, color: _textColor),
      decoration: _inputDecoration(
        hint: '••••••••',
        suffix: GestureDetector(
          onTap: () => setState(() => _obscurePassword = !_obscurePassword),
          child: Icon(
            _obscurePassword
                ? Icons.lock_outline_rounded
                : Icons.lock_open_rounded,
            size: 18,
            color: _hintColor,
          ),
        ),
      ),
      validator: (v) {
        if (v == null || v.isEmpty) return 'Ingrese su contraseña';
        if (v.length < 6) return 'Mínimo 6 caracteres';
        return null;
      },
    );
  }

  InputDecoration _inputDecoration({required String hint, Widget? suffix}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: _hintColor, fontSize: 14),
      suffixIcon: suffix != null
          ? Padding(padding: const EdgeInsets.only(right: 12), child: suffix)
          : null,
      suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
      filled: true,
      fillColor: _lightBlue,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _borderColor)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _borderColor)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _primaryBlue, width: 1.5)),
      errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent)),
      focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5)),
    );
  }

  Widget _buildLoginButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryBlue,
          foregroundColor: Colors.white,
          disabledBackgroundColor: _primaryBlue.withValues(alpha: 0.6),
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2.5))
            : const Text('Iniciar sesión',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3)),
      ),
    );
  }

  Widget _buildRegisterSection() {
    return Column(
      children: [
        const Text('¿No tiene una cuenta?',
            style: TextStyle(fontSize: 13, color: _labelColor)),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          height: 46,
          child: OutlinedButton(
            onPressed: () => Navigator.pushNamed(context, AppRoutes.register),
            style: OutlinedButton.styleFrom(
              foregroundColor: _primaryBlue,
              side: const BorderSide(color: _primaryBlue, width: 1.5),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Registrarse',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }

  // ── BIOMÉTRICO ────────────────────────────────────────────────
  Widget _buildBiometricOption() {
    return Column(
      children: [
        GestureDetector(
          onTap: () {
            // TODO: integrar local_auth
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Biométrico próximamente')),
            );
          },
          child: Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4)),
              ],
            ),
            child: const Icon(Icons.fingerprint_rounded,
                size: 30, color: _primaryBlue),
          ),
        ),
        const SizedBox(height: 8),
        const Text('Ingreso Biométrico',
            style: TextStyle(
                fontSize: 12, color: _labelColor, fontWeight: FontWeight.w500)),
      ],
    );
  }
}
