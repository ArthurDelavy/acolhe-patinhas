import 'package:flutter/material.dart';
import 'package:jwt_decoder/jwt_decoder.dart'; //decoding JWT to check if the user must accept the terms
import 'auth_modal.dart';
import '../../utils/validators.dart';
import '../../services/auth_service.dart';
import '../../utils/token_storage.dart';
import '../auth/forgot_password_modal.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool anonymousEntry = false;
  bool obscurePassword = true;

  final _formKey = GlobalKey<FormState>();
  late AuthService _authService;
  bool _isLoggingIn = false;

  static const Color primaryColor = Color(0xFFFFA94D);
  static const Color secondaryColor = Color(0xFFFF8C42);

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _authService = AuthService(baseUrl: 'http://localhost:8080');
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
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

                  // =========================================================
                  // Chamada dinâmica da API (Substitui o Text fixo antigo)
                  // =========================================================
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
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Text(
                                'Erro ao carregar o termo:\n${snapshot.error}',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          );
                        }

                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return const Center(
                            child: Text('Nenhum texto encontrado no termo.'),
                          );
                        }

                        return SingleChildScrollView(
                          controller: scrollController,
                          physics: const BouncingScrollPhysics(),
                          child: Text(
                            snapshot.data!,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF2D3142),
                              height: 1.5,
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // =========================================================
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

  Future<void> _showTermsDialog() async {
    bool aceitou = false;
    bool carregando = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Column(
                children: [
                  Icon(
                    Icons.assignment_late_outlined,
                    size: 48,
                    color: secondaryColor,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Termos Atualizados',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3142),
                      fontSize: 20,
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Para continuar utilizando o AcolhePatinhas, é necessário concordar com a nova versão do termo de compromisso.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: Color(0xFF6C757D)),
                  ),
                  const SizedBox(height: 16),

                  // AVISO VERMELHO E CHECKBOX ESTILIZADO
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: aceitou ? Colors.transparent : Colors.red.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: aceitou
                          ? null
                          : Border.all(color: Colors.red.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Checkbox(
                              value: aceitou,
                              activeColor: secondaryColor,
                              onChanged: (valor) =>
                                  setState(() => aceitou = valor ?? false),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: _showFullTextOfTerm,
                                child: const Text(
                                  'Li e concordo com os Termos',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: secondaryColor,
                                    fontWeight: FontWeight.bold,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (!aceitou)
                          const Padding(
                            padding: EdgeInsets.only(left: 12, bottom: 6),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  size: 14,
                                  color: Colors.red,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Pendente: Marque a caixa para liberar o acesso.',
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
                ],
              ),
              actions: [
                TextButton(
                  onPressed: carregando
                      ? null
                      : () {
                          TokenStorage.clear();
                          Navigator.pop(context, false);
                        },
                  child: const Text(
                    'Cancelar',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  onPressed: (aceitou && !carregando)
                      ? () async {
                          setState(() => carregando = true);
                          try {
                            await _authService.acceptTerms();
                            await _authService.login(
                              email: _emailController.text.trim(),
                              password: _passwordController.text,
                            );
                            if (!mounted) return;
                            Navigator.pop(context, true);
                          } catch (e) {
                            setState(() => carregando = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Erro ao aceitar termos.'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: secondaryColor,
                    disabledBackgroundColor: Colors.grey.shade300,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: carregando
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Continuar',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ],
            );
          },
        );
      },
    ).then((sucesso) {
      if (sucesso == true) {
        Navigator.pushReplacementNamed(context, '/feed');
      }
    });
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoggingIn = true);

    try {
      final authData = await _authService.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;

      final token = authData['accessToken'] as String;
      Map<String, dynamic> decodedToken = JwtDecoder.decode(token);

      bool mustAcceptTerms = decodedToken['mustAcceptTerms'] ?? false;

      if (mustAcceptTerms) {
        _showTermsDialog();
      } else {
        Navigator.pushReplacementNamed(context, '/feed');
      }
    } catch (e) {
      if (!mounted) return;

      if (e.toString().contains('CONTA_NAO_VERIFICADA')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Conta não verificada. Enviando novo código...'),
            backgroundColor: primaryColor,
            duration: Duration(seconds: 3),
          ),
        );

        try {
          await _authService.resendCode(email: _emailController.text.trim());
          if (!mounted) return;

          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            backgroundColor: Colors.white,
            builder: (context) => AuthRegisterModal(
              startInVerificationMode: true,
              initialEmail: _emailController.text.trim(),
            ),
          );
        } catch (resendError) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Erro ao reenviar o código.')),
          );
        }
      } else {
        String message = 'Erro ao realizar login';
        if (e.toString().contains('E-mail ou senha incorretos')) {
          message = 'E-mail ou senha incorretos';
        } else if (e.toString().contains('Dados inválidos')) {
          message = 'Verifique os dados informados';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoggingIn = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            ClipPath(
              clipper: _HeaderClipper(),
              child: Container(
                width: double.infinity,
                height: MediaQuery.of(context).size.height * 0.28,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [primaryColor, secondaryColor],
                  ),
                ),
                child: UnconstrainedBox(
                  child: Image.asset(
                    'assets/img/image-inicial.png',
                    width: 140,
                    height: 140,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'AcolhePatinhas',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF2D3142),
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Em parceria, Associação Acolher',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[500],
                      ),
                    ),
                    const SizedBox(height: 32),
                    AnimatedCrossFade(
                      duration: const Duration(milliseconds: 200),
                      crossFadeState: anonymousEntry
                          ? CrossFadeState.showSecond
                          : CrossFadeState.showFirst,
                      firstChild: Column(
                        children: [
                          _buildInput(
                            label: 'E-mail',
                            hint: 'Digite seu e-mail',
                            icon: Icons.email_outlined,
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [AutofillHints.email],
                            validator: (value) {
                              if (anonymousEntry) return null;
                              if (value == null || value.isEmpty)
                                return 'Digite seu e-mail';
                              if (!Validators.isValidEmail(value))
                                return 'Digite um e-mail válido';
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                          _buildInput(
                            label: 'Senha',
                            hint: 'Digite sua senha',
                            icon: Icons.lock_outline,
                            controller: _passwordController,
                            obscureText: obscurePassword,
                            textInputAction: TextInputAction.done,
                            suffixIcon: IconButton(
                              icon: Icon(
                                obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: Colors.grey[500],
                                size: 20,
                              ),
                              onPressed: () => setState(
                                () => obscurePassword = !obscurePassword,
                              ),
                            ),
                            validator: (value) {
                              if (anonymousEntry) return null;
                              if (value == null || value.isEmpty)
                                return 'Digite sua senha';
                              if (!Validators.isValidPassword(value))
                                return 'A senha deve ter pelo menos 6 caracteres, um número e um caractere especial';
                              return null;
                            },
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              TextButton(
                                onPressed: () {
                                  showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    shape: const RoundedRectangleBorder(
                                      borderRadius: BorderRadius.vertical(
                                        top: Radius.circular(24),
                                      ),
                                    ),
                                    backgroundColor: Colors.white,
                                    builder: (context) =>
                                        const AuthRegisterModal(),
                                  );
                                },
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: const Size(50, 30),
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: const Text(
                                  'Novo? Cadastre-se',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: secondaryColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: () async {
                                  final email = _emailController.text.trim();
                                  final resetDone =
                                      await showModalBottomSheet<bool>(
                                        context: context,
                                        isScrollControlled: true,
                                        shape: const RoundedRectangleBorder(
                                          borderRadius: BorderRadius.vertical(
                                            top: Radius.circular(24),
                                          ),
                                        ),
                                        backgroundColor: Colors.white,
                                        builder: (context) =>
                                            ForgotPasswordModal(
                                              initialEmail:
                                                  Validators.isValidEmail(email)
                                                  ? email
                                                  : null,
                                            ),
                                      );
                                  if (resetDone == true)
                                    _passwordController.clear();
                                },
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: const Size(50, 30),
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: const Text(
                                  'Esqueceu a senha?',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: secondaryColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      secondChild: Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _buildInput(
                          label: 'Nome',
                          hint: 'Digite seu nome',
                          icon: Icons.person_outline,
                          controller: _nameController,
                          textInputAction: TextInputAction.done,
                          validator: (value) {
                            if (!anonymousEntry) return null;
                            if (value == null || value.trim().isEmpty)
                              return 'Digite seu nome';
                            return null;
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoggingIn
                            ? null
                            : () async {
                                if (anonymousEntry) {
                                  if (_formKey.currentState!.validate()) {
                                    setState(() => _isLoggingIn = true);
                                    try {
                                      await TokenStorage.clear();
                                      await _authService.loginAnonymous();
                                      if (!mounted) return;
                                      Navigator.pushReplacementNamed(
                                        context,
                                        '/feed',
                                      );
                                    } catch (e) {
                                      if (!mounted) return;
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Erro ao entrar como anônimo.',
                                          ),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    } finally {
                                      if (mounted)
                                        setState(() => _isLoggingIn = false);
                                    }
                                  }
                                } else {
                                  _login();
                                }
                              },
                        style:
                            ElevatedButton.styleFrom(
                              padding: EdgeInsets.zero,
                              elevation: 3,
                              shadowColor: secondaryColor.withOpacity(0.3),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ).copyWith(
                              backgroundColor: WidgetStateProperty.all(
                                Colors.transparent,
                              ),
                            ),
                        child: Ink(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [primaryColor, secondaryColor],
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Container(
                            alignment: Alignment.center,
                            child: _isLoggingIn
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    anonymousEntry
                                        ? 'Entrar como Anônimo'
                                        : 'Entrar',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: Divider(
                            color: Colors.grey.shade300,
                            thickness: 1,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'OU',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade400,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            color: Colors.grey.shade300,
                            thickness: 1,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    OutlinedButton.icon(
                      onPressed: () {
                        setState(() => anonymousEntry = !anonymousEntry);
                        _formKey.currentState?.reset();
                      },
                      icon: Icon(
                        anonymousEntry
                            ? Icons.arrow_back
                            : Icons.person_off_outlined,
                        size: 18,
                      ),
                      label: Text(
                        anonymousEntry
                            ? 'Cancelar entrada anônima'
                            : 'Entrar anônimo',
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        foregroundColor: secondaryColor,
                        side: BorderSide(
                          color: primaryColor.withOpacity(0.4),
                          width: 1.2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
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

  Widget _buildInput({
    required String label,
    required String hint,
    required IconData icon,
    TextEditingController? controller,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    bool obscureText = false,
    Widget? suffixIcon,
    Iterable<String>? autofillHints,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      autofillHints: autofillHints,
      validator: validator,
      style: const TextStyle(fontSize: 15, color: Color(0xFF2D3142)),
      decoration: InputDecoration(
        floatingLabelStyle: const TextStyle(
          color: secondaryColor,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: secondaryColor, size: 20),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: const Color(0xFFFAFAFA),
        contentPadding: const EdgeInsets.only(
          top: 22,
          bottom: 10,
          left: 16,
          right: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade200),
          gapPadding: 6,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: secondaryColor, width: 1.5),
        ),
      ),
    );
  }
}

class _HeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 30);
    path.quadraticBezierTo(
      size.width / 2,
      size.height + 15,
      size.width,
      size.height - 30,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
