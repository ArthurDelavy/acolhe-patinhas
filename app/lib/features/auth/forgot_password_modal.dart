import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../utils/validators.dart';
import '../../services/auth_service.dart';

/// Fecha com `Navigator.pop(true)` quando a senha é redefinida.
class ForgotPasswordModal extends StatefulWidget {
  final String? initialEmail;

  const ForgotPasswordModal({super.key, this.initialEmail});

  @override
  State<ForgotPasswordModal> createState() => _ForgotPasswordModalState();
}

class _ForgotPasswordModalState extends State<ForgotPasswordModal> {
  static const Color primaryColor = Color(0xFFFFA94D);
  static const Color secondaryColor = Color(0xFFFF8C42);

  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService(baseUrl: 'http://localhost:8080');

  late final _emailController = TextEditingController(
    text: widget.initialEmail,
  );
  final _passwordController = TextEditingController();
  final _codeControllers = List.generate(6, (_) => TextEditingController());

  bool _codeSent = false;
  bool _isLoading = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    for (final c in _codeControllers) {
      c.dispose();
    }
    super.dispose();
  }

  // --------------------------- Lógica ---------------------------

  /// Liga o loading, executa a ação e guarda a mensagem se der erro.
  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      await action();
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _codeSent ? await _reset() : await _sendCode();
  }

  // O back nunca diz se o e-mail existe, então sempre avançamos.
  Future<void> _sendCode() => _run(() async {
    await _authService.forgotPassword(email: _emailController.text.trim());
    for (final c in _codeControllers) {
      c.clear();
    }
    _codeSent = true;
  });

  Future<void> _reset() async {
    final code = _codeControllers.map((c) => c.text).join().toUpperCase();
    if (code.length < 6) {
      setState(() => _error = 'Digite os 6 caracteres do código.');
      return;
    }

    await _run(() async {
      await _authService.resetPassword(
        email: _emailController.text.trim(),
        code: code,
        newPassword: _passwordController.text,
      );

      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop(true);
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Senha redefinida! Entre com a nova senha.'),
          backgroundColor: Color(0xFF2E7D32),
          behavior: SnackBarBehavior.floating,
        ),
      );
    });
  }

  void _back() {
    if (_codeSent) {
      setState(() {
        _codeSent = false;
        _error = null;
      });
    } else {
      Navigator.of(context).pop();
    }
  }

  // ----------------------------- UI -----------------------------

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final bottom = mq.viewInsets.bottom > 0
        ? mq.viewInsets.bottom
        : mq.padding.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 20, 24, bottom + 20),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: AnimatedSize(
          duration: const Duration(milliseconds: 200),
          alignment: Alignment.topCenter,
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Esqueceu a senha?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3142),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _codeSent
                      ? 'Se ${_emailController.text.trim()} estiver cadastrado, enviamos um código para esse e-mail.'
                      : 'Informe o e-mail da sua conta e enviaremos um código para criar uma nova senha.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
                const SizedBox(height: 20),

                _field(
                  label: 'E-mail',
                  hint: 'Digite seu e-mail',
                  icon: Icons.email_outlined,
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  enabled: !_codeSent,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty)
                      return 'Digite seu e-mail';
                    if (!Validators.isValidEmail(v.trim()))
                      return 'Digite um e-mail válido';
                    return null;
                  },
                ),

                if (_codeSent) ...[
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(6, _codeBox),
                  ),
                  const SizedBox(height: 20),
                  _field(
                    label: 'Nova senha',
                    hint: 'Crie uma nova senha',
                    icon: Icons.lock_outline,
                    controller: _passwordController,
                    obscure: _obscure,
                    suffix: IconButton(
                      icon: Icon(
                        _obscure
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: Colors.grey[500],
                        size: 20,
                      ),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Digite a nova senha';
                      if (!Validators.isValidPassword(v)) {
                        return 'Mínimo 8 caracteres, com maiúscula, minúscula, número e caractere especial (@\$!%*?&)';
                      }
                      return null;
                    },
                  ),
                ],

                const SizedBox(height: 20),

                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                _button(
                  _codeSent ? 'Redefinir senha' : 'Enviar código',
                  _isLoading ? null : _submit,
                ),

                const SizedBox(height: 8),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton(
                      onPressed: _isLoading ? null : _back,
                      child: Text(
                        _codeSent ? 'Alterar e-mail' : 'Cancelar',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    if (_codeSent)
                      TextButton(
                        onPressed: _isLoading ? null : _sendCode,
                        child: const Text(
                          'Reenviar código',
                          style: TextStyle(
                            color: secondaryColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  OutlineInputBorder _border(Color color, [double width = 1]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: color, width: width),
      );

  Widget _codeBox(int i) {
    return SizedBox(
      width: 46,
      height: 55,
      child: TextField(
        controller: _codeControllers[i],
        textAlign: TextAlign.center,
        textCapitalization: TextCapitalization.characters,
        maxLength: 1,
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
        ],
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Color(0xFF2D3142),
        ),
        onChanged: (v) {
          final focus = FocusScope.of(context);
          if (v.isNotEmpty) {
            focus.nextFocus();
          } else if (i > 0) {
            focus.previousFocus();
          }
        },
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: const Color(0xFFFAFAFA),
          contentPadding: EdgeInsets.zero,
          enabledBorder: _border(Colors.grey.shade300),
          focusedBorder: _border(secondaryColor, 2),
        ),
      ),
    );
  }

  Widget _field({
    required String label,
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    required String? Function(String?) validator,
    TextInputType? keyboardType,
    bool obscure = false,
    bool enabled = true,
    Widget? suffix,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      obscureText: obscure,
      enabled: enabled,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 14, color: Color(0xFF2D3142)),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
        floatingLabelStyle: const TextStyle(
          color: secondaryColor,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
        prefixIcon: Icon(icon, color: secondaryColor, size: 20),
        suffixIcon: suffix,
        filled: true,
        fillColor: const Color(0xFFFAFAFA),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 14,
          horizontal: 16,
        ),
        errorMaxLines: 3,
        enabledBorder: _border(Colors.grey.shade200),
        disabledBorder: _border(Colors.grey.shade200),
        focusedBorder: _border(secondaryColor, 1.5),
      ),
    );
  }

  Widget _button(String text, VoidCallback? onPressed) {
    return SizedBox(
      height: 48,
      child: ElevatedButton(
        onPressed: onPressed,
        style:
            ElevatedButton.styleFrom(
              padding: EdgeInsets.zero,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ).copyWith(
              backgroundColor: WidgetStateProperty.all(Colors.transparent),
            ),
        child: Ink(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [primaryColor, secondaryColor],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    text,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
