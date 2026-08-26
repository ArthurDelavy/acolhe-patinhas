import 'package:flutter/material.dart';
import '../../utils/validators.dart';
import '../../services/auth_service.dart';

class AuthRegisterModal extends StatefulWidget {
  const AuthRegisterModal({super.key});

  @override
  State<AuthRegisterModal> createState() => _AuthRegisterModalState();
}

class _AuthRegisterModalState extends State<AuthRegisterModal> {
  bool _obscurePassword = true;
  bool _isVerifyingCode = false;
  bool _isEmailVerified = false;

  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  late final AuthService _authService;
  bool _isRegistering = false;

  @override
  void initState() {
    super.initState();

    _authService = AuthService(baseUrl: 'http://localhost:8080');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  static const Color primaryColor = Color(0xFFFFA94D);
  static const Color secondaryColor = Color(0xFFFF8C42);

  @override
  Widget build(BuildContext context) {
    // controls the mobile phone keyboard
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 20,
        bottom: bottomInset + 20,
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          //controls which screen to render
          child: _isVerifyingCode ? _buildCodeStep() : _buildFormStep(),
        ),
      ),
    );
  }

  //first screen (the modal)

  Widget _buildFormStep() {
    return Form(
      key: _formKey,
      child: Column(
        key: const ValueKey('form_step'),
        mainAxisSize: MainAxisSize.min, //the height of the modal
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
            'Criar Conta',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3142),
            ),
          ),

          const SizedBox(height: 20),

          _buildField(
            label: 'Nome completo',
            hint: 'Digite seu nome',
            icon: Icons.person_outline,
            controller: _nameController,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Digite seu nome';
              }

              return null;
            },
          ),

          const SizedBox(height: 14),

          _buildField(
            label: 'E-mail',
            hint: 'Digite seu e-mail',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            controller: _emailController,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Digite seu e-mail';
              }

              if (!Validators.isValidEmail(value.trim())) {
                return 'Digite um e-mail válido';
              }

              return null;
            },
          ),

          const SizedBox(height: 14),

          _buildField(
            label: 'Senha',
            hint: 'Crie uma senha',
            icon: Icons.lock_outline,
            obscureText: _obscurePassword,
            controller: _passwordController,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: Colors.grey[500],
                size: 20,
              ),

              //view password
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Digite uma senha';
              }

              if (!Validators.isValidPassword(value)) {
                return 'Mínimo 8 caracteres, com maiúscula, minúscula, número e caractere especial';
              }

              return null;
            },
          ),

          const SizedBox(height: 24),

          _buildGradientButton(
            text: 'Cadastrar',
            // Updates the screen by triggering a layout change
            onPressed: () {
              if (!_formKey.currentState!.validate()) {
                return;
              }

              setState(() {
                _isVerifyingCode = true;
              });
            },
          ),
        ],
      ),
    );
  }

  //second screen (code verification)

  Widget _buildCodeStep() {
    return Column(
      key: const ValueKey('code_step'),
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
          'Verificação de E-mail',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D3142),
          ),
        ),

        const SizedBox(height: 8),

        Text(
          'Insira o código enviado para o seu e-mail.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
        ),

        const SizedBox(height: 24),

        //Build a box with 4 squares.
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(4, (_) => _buildCodeBox()),
        ),

        const SizedBox(height: 24),

        _buildGradientButton(
          text: _isRegistering ? 'Cadastrando...' : 'Verificar e Concluir',
          onPressed: _isRegistering
              ? null
              : () async {
                  setState(() => _isRegistering = true);

                  try {
                    await _authService.register(
                      name: _nameController.text.trim(),
                      email: _emailController.text.trim(),
                      password: _passwordController.text,
                    );

                    if (!mounted) return;

                    setState(() {
                      _isRegistering = false;
                      _isVerifyingCode = false;
                      _isEmailVerified = true;
                    });

                    final messenger = ScaffoldMessenger.of(context);

                    //displays the message
                    messenger.showSnackBar(
                      SnackBar(
                        content: const Row(
                          children: [
                            Icon(
                              Icons.check_circle_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                            SizedBox(width: 10),
                            Text(
                              'Conta criada com sucesso!',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        backgroundColor: const Color(0xFF2E7D32),
                        behavior: SnackBarBehavior.floating,
                        duration: const Duration(seconds: 2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        margin: const EdgeInsets.all(16),
                      ),
                    );
                  } catch (e) {
                    if (!mounted) return;

                    setState(() => _isRegistering = false);

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          e.toString().replaceFirst('Exception: ', ''),
                        ),
                      ),
                    );
                  }
                },
        ),

        const SizedBox(height: 8),

        TextButton(
          onPressed: () => setState(() => _isVerifyingCode = false),
          child: const Text(
            'Voltar',
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
        ),

        if (_isEmailVerified) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, color: Color(0xFF2E7D32), size: 18),
                SizedBox(width: 6),
                Text(
                  'E-mail verificado',
                  style: TextStyle(
                    color: Color(0xFF2E7D32),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  //square constructor for later use
  Widget _buildCodeBox() {
    return SizedBox(
      width: 50,
      height: 55,
      child: TextField(
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Color(0xFF2D3142),
        ),

        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: const Color(0xFFFAFAFA),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: secondaryColor, width: 2),
          ),
        ),
      ),
    );
  }

  //input constructor
  Widget _buildField({
    required String label,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    TextInputType? keyboardType,
    Widget? suffixIcon,
    TextEditingController? controller,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      obscureText: obscureText,
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
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: const Color(0xFFFAFAFA),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 14,
          horizontal: 16,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: secondaryColor, width: 1.5),
        ),
      ),
    );
  }

  //button constructor with gradient background
  Widget _buildGradientButton({
    required String text,
    required VoidCallback? onPressed,
  }) {
    return SizedBox(
      height: 48,
      child: ElevatedButton(
        onPressed: onPressed,
        style:
            ElevatedButton.styleFrom(
              padding: EdgeInsets.zero,
              elevation: 2,
              shadowColor: secondaryColor.withOpacity(0.3),
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
          child: Container(
            alignment: Alignment.center,
            child: Text(
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
