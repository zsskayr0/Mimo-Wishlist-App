import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/layout/breakpoints.dart';
import '../../core/theme/mimo_colors.dart';

/// Login / Cadastro, built to match the reference layout the user supplied:
/// dark split panel on wide windows (textured image left, form right),
/// form-only on phone width since the reference itself is a desktop
/// composition that doesn't have room to keep the image on a narrow screen.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _isSignUp = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _rememberMe = true;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _setSignUp(bool value) {
    setState(() {
      _isSignUp = value;
      _errorMessage = null;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final auth = Supabase.instance.client.auth;
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    try {
      if (_isSignUp) {
        await auth.signUp(
          email: email,
          password: password,
          data: {'display_name': _nameController.text.trim()},
        );
      } else {
        await auth.signInWithPassword(email: email, password: password);
      }
      // On success, AuthGate's stream rebuilds into the app automatically.
    } on AuthException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (_) {
      setState(() => _errorMessage = 'Não deu pra conectar. Tenta de novo.');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _forgotPassword() async {
    final controller = TextEditingController(text: _emailController.text.trim());
    final email = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: MimoColors.authPanel,
        title: const Text('Recuperar senha', style: TextStyle(color: MimoColors.authText)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.emailAddress,
          style: const TextStyle(color: MimoColors.authText),
          decoration: _authInputDecoration(hint: 'Seu e-mail'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Enviar link'),
          ),
        ],
      ),
    );

    if (email == null || email.isEmpty || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(email);
      messenger.showSnackBar(const SnackBar(content: Text('Link de recuperação enviado, se o e-mail existir.')));
    } catch (_) {
      messenger.showSnackBar(const SnackBar(content: Text('Não deu pra enviar. Tenta de novo.')));
    }
  }

  void _socialComingSoon(String provider) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Entrar com $provider ainda não está disponível.')));
  }

  static InputDecoration _authInputDecoration({required String hint}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: MimoColors.authPlaceholder, fontSize: 14),
      filled: true,
      fillColor: MimoColors.authInputBg,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: MimoColors.authBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: MimoColors.authBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: MimoColors.gradientA),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final desktop = MimoBreakpoints.isDesktop(constraints.maxWidth);
        return Scaffold(
          backgroundColor: MimoColors.authBg,
          body: desktop ? _splitLayout() : _formOnlyLayout(),
        );
      },
    );
  }

  Widget _splitLayout() {
    return Row(
      children: [
        Expanded(
          child: Image.asset('assets/images/auth_background.jpg', fit: BoxFit.cover, height: double.infinity),
        ),
        SizedBox(
          width: 500,
          child: Container(
            color: MimoColors.authBg,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: SingleChildScrollView(child: _buildForm(context)),
          ),
        ),
      ],
    );
  }

  Widget _formOnlyLayout() {
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: _buildForm(context),
          ),
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    final isSignUp = _isSignUp;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Column(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(gradient: MimoColors.gradient, borderRadius: BorderRadius.circular(16)),
                  child: const Icon(Icons.favorite, color: Colors.white, size: 24),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Mimo',
                  style: TextStyle(color: MimoColors.authText, fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(color: MimoColors.authInputBg, borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                Expanded(
                  child: _TabButton(label: 'Login', active: !isSignUp, onTap: () => _setSignUp(false)),
                ),
                Expanded(
                  child: _TabButton(label: 'Cadastro', active: isSignUp, onTap: () => _setSignUp(true)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          if (isSignUp) ...[
            const _FieldLabel('Nome completo'),
            TextFormField(
              controller: _nameController,
              style: const TextStyle(color: MimoColors.authText),
              decoration: _authInputDecoration(hint: 'Seu nome'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Como podemos te chamar?' : null,
            ),
            const SizedBox(height: 16),
          ],
          const _FieldLabel('E-mail'),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            style: const TextStyle(color: MimoColors.authText),
            decoration: _authInputDecoration(hint: isSignUp ? 'exemplo@gmail.com' : 'Seu e-mail'),
            validator: (v) => (v == null || !v.contains('@')) ? 'E-mail inválido' : null,
          ),
          const SizedBox(height: 16),
          _FieldLabel(isSignUp ? 'Criar uma senha' : 'Senha'),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            autofillHints: const [AutofillHints.password],
            style: const TextStyle(color: MimoColors.authText),
            decoration: _authInputDecoration(hint: isSignUp ? 'mínimo de 8 caracteres' : 'Senha').copyWith(
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: MimoColors.authPlaceholder,
                  size: 19,
                ),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            validator: (v) => (v == null || v.length < (isSignUp ? 8 : 6)) ? 'Senha muito curta' : null,
          ),
          if (isSignUp) ...[
            const SizedBox(height: 16),
            const _FieldLabel('Confirmar senha'),
            TextFormField(
              controller: _confirmController,
              obscureText: _obscureConfirm,
              style: const TextStyle(color: MimoColors.authText),
              decoration: _authInputDecoration(hint: 'repita a senha').copyWith(
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: MimoColors.authPlaceholder,
                    size: 19,
                  ),
                  onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                ),
              ),
              validator: (v) => v != _passwordController.text ? 'As senhas não coincidem' : null,
            ),
          ] else ...[
            const SizedBox(height: 10),
            Row(
              children: [
                SizedBox(
                  width: 22,
                  height: 22,
                  child: Checkbox(
                    value: _rememberMe,
                    onChanged: (v) => setState(() => _rememberMe = v ?? true),
                    activeColor: MimoColors.gradientA,
                    side: const BorderSide(color: MimoColors.authBorder),
                  ),
                ),
                const SizedBox(width: 8),
                const Text('Lembrar de mim', style: TextStyle(color: MimoColors.authPlaceholder, fontSize: 13)),
                const Spacer(),
                TextButton(
                  onPressed: _forgotPassword,
                  child: const Text('Esqueceu a senha?', style: TextStyle(fontSize: 12.5)),
                ),
              ],
            ),
          ],
          if (_errorMessage != null) ...[
            const SizedBox(height: 14),
            Text(_errorMessage!, style: const TextStyle(color: Color(0xFFEF6E6E)), textAlign: TextAlign.center),
          ],
          const SizedBox(height: 22),
          FilledButton(
            onPressed: _isSubmitting ? null : _submit,
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                  )
                : Text(isSignUp ? 'Criar conta' : 'Entrar', style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 22),
          Row(
            children: const [
              Expanded(child: Divider(color: MimoColors.authBorder)),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text('Ou', style: TextStyle(color: MimoColors.authPlaceholder, fontSize: 12.5)),
              ),
              Expanded(child: Divider(color: MimoColors.authBorder)),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(child: _SocialButton(kind: _SocialKind.facebook, onTap: () => _socialComingSoon('Facebook'))),
              const SizedBox(width: 10),
              Expanded(child: _SocialButton(kind: _SocialKind.google, onTap: () => _socialComingSoon('Google'))),
              const SizedBox(width: 10),
              Expanded(child: _SocialButton(kind: _SocialKind.apple, onTap: () => _socialComingSoon('Apple'))),
            ],
          ),
          const SizedBox(height: 22),
          Center(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(color: MimoColors.authPlaceholder, fontSize: 13),
                children: [
                  TextSpan(text: isSignUp ? 'Já tem conta? ' : 'Não tem conta? '),
                  TextSpan(
                    text: isSignUp ? 'Entrar' : 'Cadastre-se',
                    style: const TextStyle(color: MimoColors.authText, fontWeight: FontWeight.bold),
                    recognizer: TapGestureRecognizer()..onTap = () => _setSignUp(!isSignUp),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Text(
        label,
        style: const TextStyle(color: MimoColors.authText, fontSize: 13, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({required this.label, required this.active, required this.onTap});

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: active ? MimoColors.authPanel : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
          border: active ? Border.all(color: MimoColors.authBorder) : null,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: active ? MimoColors.authText : MimoColors.authPlaceholder,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

enum _SocialKind { facebook, google, apple }

class _SocialButton extends StatelessWidget {
  const _SocialButton({required this.kind, required this.onTap});

  final _SocialKind kind;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: MimoColors.authInputBg,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: MimoColors.authBorder),
          ),
          alignment: Alignment.center,
          child: _icon(),
        ),
      ),
    );
  }

  Widget _icon() {
    switch (kind) {
      case _SocialKind.facebook:
        return Container(
          width: 22,
          height: 22,
          decoration: const BoxDecoration(color: Color(0xFF1877F2), shape: BoxShape.circle),
          alignment: Alignment.center,
          child: const Text(
            'f',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15, height: 1),
          ),
        );
      case _SocialKind.google:
        return const Text(
          'G',
          style: TextStyle(color: Color(0xFF4285F4), fontWeight: FontWeight.bold, fontSize: 18),
        );
      case _SocialKind.apple:
        return const Icon(Icons.apple, color: Colors.white, size: 22);
    }
  }
}
