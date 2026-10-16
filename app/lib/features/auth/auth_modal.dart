import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../utils/validators.dart';
import '../../services/auth_service.dart';
import 'package:flutter_markdown/flutter_markdown.dart'; // new import for Markdown rendering

class AuthRegisterModal extends StatefulWidget {
  final bool startInVerificationMode;
  final String? initialEmail;

  const AuthRegisterModal({
    super.key,
    this.startInVerificationMode = false,
    this.initialEmail,
  });

  @override
  State<AuthRegisterModal> createState() => _AuthRegisterModalState();
}

class _AuthRegisterModalState extends State<AuthRegisterModal> {
  static const Color primaryColor = Color(0xFFFFA94D);
  static const Color secondaryColor = Color(0xFFFF8C42);

  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService(baseUrl: 'http://localhost:8080');

  final _nameController = TextEditingController();
  late final _emailController = TextEditingController(
    text: widget.initialEmail,
  );
  final _passwordController = TextEditingController();
  final _codeControllers = List.generate(6, (_) => TextEditingController());

  late bool _isVerifyingCode = widget.startInVerificationMode;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _aceitouTermos = false; // NOVO: Controle da caixinha de termos

  String? _error;
  String? _info;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    for (final c in _codeControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _showFullTextOfTerm() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: Colors.white,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.8,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              padding: const EdgeInsets.all(24),
              child: Column(
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
                    'Termos de Compromisso',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3142),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Expanded(
                    child: FutureBuilder<String>(
                      future: _authService.fetchTermContent(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(
                              color: secondaryColor,
                            ),
                          );
                        }
                        if (snapshot.hasError) {
                          return Center(
                            child: Text(
                              'Erro ao carregar o termo:\n${snapshot.error}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 13,
                              ),
                            ),
                          );
                        }
                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return const Center(
                            child: Text('Nenhum texto encontrado no termo.'),
                          );
                        }

                        // RENDERIZADOR MARKDOWN PERSONALIZADO
                        return SingleChildScrollView(
                          controller: scrollController,
                          physics: const BouncingScrollPhysics(),
                          child: MarkdownBody(
                            data: snapshot.data!,
                            styleSheet: MarkdownStyleSheet(
                              h1: const TextStyle(
                                color: secondaryColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                              h2: const TextStyle(
                                color: Color(0xFF2D3142),
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                              p: const TextStyle(
                                color: Color(0xFF2D3142),
                                fontSize: 14,
                                height: 1.5,
                              ),
                              strong: const TextStyle(
                                color: secondaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                              listBullet: const TextStyle(
                                color: secondaryColor,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: secondaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'Fechar',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _isLoading = true;
      _error = null;
      _info = null;
    });
    try {
      await action();
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_aceitouTermos) return; // Segurança extra

    await _run(() async {
      await _authService.register(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        acceptTerms:
            _aceitouTermos, // Enviando a flag (precisa atualizar o AuthService)
      );
      _isVerifyingCode = true;
    });
  }

  Future<void> _verify() => _run(() async {
    final code = _codeControllers
        .map((c) => c.text)
        .join()
        .trim()
        .toUpperCase();
    if (code.length < 6) throw Exception('Digite os 6 caracteres do código.');

    await _authService.verifyCode(
      email: _emailController.text.trim(),
      code: code,
    );

    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop(true);
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Conta verificada com sucesso!'),
        backgroundColor: Color(0xFF2E7D32),
        behavior: SnackBarBehavior.floating,
      ),
    );
  });

  Future<void> _resend() => _run(() async {
    await _authService.resendCode(email: _emailController.text.trim());
    for (final c in _codeControllers) {
      c.clear();
    }
    _info = 'Enviamos um novo código para o seu e-mail.';
  });

  void _back() {
    if (widget.startInVerificationMode) {
      Navigator.of(context).pop();
    } else {
      setState(() {
        _isVerifyingCode = false;
        _error = null;
        _info = null;
      });
    }
  }

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
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _isVerifyingCode ? _buildCodeStep() : _buildFormStep(),
        ),
      ),
    );
  }

  Widget _buildFormStep() {
    return Form(
      key: _formKey,
      child: Column(
        key: const ValueKey('form_step'),
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _header('Criar Conta'),
          const SizedBox(height: 20),
          _field(
            label: 'Nome completo',
            hint: 'Digite seu nome',
            icon: Icons.person_outline,
            controller: _nameController,
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Digite seu nome' : null,
          ),
          const SizedBox(height: 14),
          _field(
            label: 'E-mail',
            hint: 'Digite seu e-mail',
            icon: Icons.email_outlined,
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Digite seu e-mail';
              if (!Validators.isValidEmail(v.trim()))
                return 'Digite um e-mail válido';
              return null;
            },
          ),
          const SizedBox(height: 14),
          _field(
            label: 'Senha',
            hint: 'Crie uma senha',
            icon: Icons.lock_outline,
            controller: _passwordController,
            obscure: _obscurePassword,
            suffix: IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: Colors.grey[500],
                size: 20,
              ),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Digite uma senha';
              if (!Validators.isValidPassword(v))
                return 'Mínimo 8 caracteres, com maiúscula, minúscula, número e caractere especial';
              return null;
            },
          ),
          const SizedBox(height: 16),

          // --- CHECKBOX E AVISO EM VERMELHO DE PENDÊNCIA ---
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: _aceitouTermos ? Colors.transparent : Colors.red.shade50,
              borderRadius: BorderRadius.circular(10),
              border: _aceitouTermos
                  ? null
                  : Border.all(color: Colors.red.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Checkbox(
                      value: _aceitouTermos,
                      activeColor: secondaryColor,
                      onChanged: (val) =>
                          setState(() => _aceitouTermos = val ?? false),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: _showFullTextOfTerm,
                        child: const Text(
                          'Li e concordo com os Termos',
                          style: TextStyle(
                            fontSize: 13,
                            color: secondaryColor,
                            decoration: TextDecoration.underline,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                if (!_aceitouTermos)
                  const Padding(
                    padding: EdgeInsets.only(left: 12, bottom: 6),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, size: 14, color: Colors.red),
                        SizedBox(width: 4),
                        Text(
                          'Atenção: Você precisa aceitar os termos para se cadastrar.',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          _message(),
          _button(
            'Cadastrar',
            (_isLoading || !_aceitouTermos) ? null : _register,
          ),
        ],
      ),
    );
  }

  Widget _buildCodeStep() {
    return Column(
      key: const ValueKey('code_step'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _header(
          'Verificação de E-mail',
          'Insira o código enviado para\n${_emailController.text.isNotEmpty ? _emailController.text : "o seu e-mail"}.',
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(6, _codeBox),
        ),
        const SizedBox(height: 24),
        _message(),
        _button('Verificar e Concluir', _isLoading ? null : _verify),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            TextButton(
              onPressed: _isLoading ? null : _back,
              child: Text(
                widget.startInVerificationMode ? 'Cancelar' : 'Voltar',
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ),
            TextButton(
              onPressed: _isLoading ? null : _resend,
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
    );
  }

  Widget _header(String title, [String? subtitle]) {
    return Column(
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
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D3142),
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
          ),
        ],
      ],
    );
  }

  Widget _message() {
    final text = _error ?? _info;
    if (text == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: _error != null ? Colors.red : const Color(0xFF2E7D32),
          fontSize: 13,
          fontWeight: FontWeight.w600,
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
      width: 50,
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
          if (v.isNotEmpty && i < 5) {
            focus.nextFocus();
          } else if (v.isEmpty && i > 0) {
            focus.previousFocus();
          }
        },
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: const Color(0xFFFAFAFA),
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
    Widget? suffix,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      obscureText: obscure,
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
