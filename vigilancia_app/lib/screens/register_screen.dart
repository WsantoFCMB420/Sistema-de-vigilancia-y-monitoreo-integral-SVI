import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../main.dart'; // AppRoutes

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _acceptTerms = false;
  bool _isLoading = false;

  static const Color _bgColor     = Color(0xFFDDE8F5);
  static const Color _primaryBlue = Color(0xFF1A5DC8);
  static const Color _lightBlue   = Color(0xFFEEF4FF);
  static const Color _cardColor   = Colors.white;
  static const Color _labelColor  = Color(0xFF6B7A99);
  static const Color _textColor   = Color(0xFF1A2340);
  static const Color _hintColor   = Color(0xFFADB8CC);
  static const Color _borderColor = Color(0xFFD0DAEA);

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // ── LÓGICA DE REGISTRO ────────────────────────────────────────
  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_acceptTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes aceptar los términos y condiciones'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:8000/api/register'), // emulador Android
        // Uri.parse('http://192.168.X.X:8000/api/register'), // dispositivo físico
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name':         _nameController.text.trim(),
          'email':        _emailController.text.trim(),
          'password':     _passwordController.text,
          'accept_terms': true,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('¡Cuenta creada! Ahora inicia sesión'),
              backgroundColor: Color(0xFF16A34A),
            ),
          );
          // ✅ Regresar al Login usando rutas nombradas
          Navigator.pushReplacementNamed(context, AppRoutes.login);
        }
      } else {
        // Error del servidor (email duplicado, validación, etc.)
        if (mounted) {
          final msg = data['message'] ?? data['error'] ?? 'Error al registrarse';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(msg), backgroundColor: Colors.redAccent),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo conectar con el servidor'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
            children: [
              _buildBrand(),
              const SizedBox(height: 28),
              _buildFormCard(),
              const SizedBox(height: 20),
              _buildLoginLink(),
            ],
          ),
        ),
      ),
    );
  }

  // ── MARCA ─────────────────────────────────────────────────────
  Widget _buildBrand() {
    return Column(
      children: [
        Container(
          width: 64, height: 64,
          decoration: BoxDecoration(
            color: _primaryBlue,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: _primaryBlue.withOpacity(0.35),
                  blurRadius: 20, offset: const Offset(0, 8)),
            ],
          ),
          child: const Icon(Icons.shield_rounded, color: Colors.white, size: 36),
        ),
        const SizedBox(height: 12),
        const Text('Sentinel Surveillance',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: _primaryBlue)),
        const SizedBox(height: 4),
        const Text('Crea tu cuenta para comenzar',
            style: TextStyle(fontSize: 13, color: _labelColor)),
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
          BoxShadow(color: Colors.black.withOpacity(0.06),
              blurRadius: 24, offset: const Offset(0, 6)),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Crear cuenta',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: _textColor)),
            const SizedBox(height: 4),
            const Text('Completa los datos para registrarte',
                style: TextStyle(fontSize: 13, color: _labelColor)),
            const SizedBox(height: 22),

            _buildLabel('NOMBRE COMPLETO'),
            const SizedBox(height: 6),
            _buildTextField(
              controller: _nameController,
              hint: 'Juan Pérez',
              icon: Icons.person_outline_rounded,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Ingresa tu nombre';
                if (v.length < 3) return 'Mínimo 3 caracteres';
                return null;
              },
            ),
            const SizedBox(height: 16),

            _buildLabel('CORREO ELECTRÓNICO'),
            const SizedBox(height: 6),
            _buildTextField(
              controller: _emailController,
              hint: 'nombre@ejemplo.com',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Ingresa tu correo';
                if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v))
                  return 'Correo no válido';
                return null;
              },
            ),
            const SizedBox(height: 16),

            _buildLabel('CONTRASEÑA'),
            const SizedBox(height: 6),
            _buildPasswordField(
              controller: _passwordController,
              hint: 'Mínimo 6 caracteres',
              obscure: _obscurePassword,
              onToggle: () => setState(() => _obscurePassword = !_obscurePassword),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Ingresa una contraseña';
                if (v.length < 6) return 'Mínimo 6 caracteres';
                return null;
              },
            ),
            const SizedBox(height: 16),

            _buildLabel('CONFIRMAR CONTRASEÑA'),
            const SizedBox(height: 6),
            _buildPasswordField(
              controller: _confirmPasswordController,
              hint: 'Repite tu contraseña',
              obscure: _obscureConfirm,
              onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Confirma tu contraseña';
                if (v != _passwordController.text) return 'Las contraseñas no coinciden';
                return null;
              },
            ),
            const SizedBox(height: 18),

            _buildTermsCheckbox(),
            const SizedBox(height: 24),
            _buildRegisterButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(text,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
            color: _labelColor, letterSpacing: 0.8));
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 14, color: _textColor),
      decoration: _inputDecoration(
          hint: hint, suffix: Icon(icon, size: 18, color: _hintColor)),
      validator: validator,
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String hint,
    required bool obscure,
    required VoidCallback onToggle,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(fontSize: 14, color: _textColor),
      decoration: _inputDecoration(
        hint: hint,
        suffix: GestureDetector(
          onTap: onToggle,
          child: Icon(
            obscure ? Icons.lock_outline_rounded : Icons.lock_open_rounded,
            size: 18, color: _hintColor,
          ),
        ),
      ),
      validator: validator,
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
      border:             OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _borderColor)),
      enabledBorder:      OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _borderColor)),
      focusedBorder:      OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _primaryBlue, width: 1.5)),
      errorBorder:        OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.redAccent)),
      focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.redAccent, width: 1.5)),
    );
  }

  Widget _buildTermsCheckbox() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 22, height: 22,
          child: Checkbox(
            value: _acceptTerms,
            activeColor: _primaryBlue,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            onChanged: (v) => setState(() => _acceptTerms = v ?? false),
          ),
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: Text('Acepto los términos y condiciones de uso',
              style: TextStyle(fontSize: 12, color: _labelColor)),
        ),
      ],
    );
  }

  Widget _buildRegisterButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleRegister,
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryBlue,
          foregroundColor: Colors.white,
          disabledBackgroundColor: _primaryBlue.withOpacity(0.6),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: _isLoading
            ? const SizedBox(width: 22, height: 22,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
            : const Text('Crear cuenta',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: 0.3)),
      ),
    );
  }

  // ── LINK AL LOGIN ─────────────────────────────────────────────
  Widget _buildLoginLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('¿Ya tienes una cuenta?',
            style: TextStyle(fontSize: 13, color: _labelColor)),
        TextButton(
          onPressed: () => Navigator.pushReplacementNamed(context, AppRoutes.login),
          child: const Text('Iniciar sesión',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _primaryBlue)),
        ),
      ],
    );
  }
}