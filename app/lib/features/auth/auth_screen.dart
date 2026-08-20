import 'package:flutter/material.dart';
import 'auth_modal.dart';
import '../../utils/validators.dart';

//FIRST
//VERSION OF THE SCREEN # I LOVE PHP

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool anonymousEntry = false;
  bool obscurePassword = true;

  // Form key
  final _formKey = GlobalKey<FormState>();

  //palet of colors
  static const Color primaryColor = Color(0xFFFFA94D);
  static const Color secondaryColor = Color(0xFFFF8C42);

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
                    'assets/img/image.png',
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
                      //section title
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
                      //section subtitle
                      'Em parceria, Associação Acolher',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[500],
                      ),
                    ),

                    const SizedBox(height: 32),

                    //reused inputs
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
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [AutofillHints.email],
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Digite seu e-mail';
                              }

                              if (!Validators.isValidEmail(value)) {
                                return 'Digite um e-mail válido';
                              }

                              return null;
                            },
                          ),

                          const SizedBox(height: 14),

                          _buildInput(
                            label: 'Senha',
                            hint: 'Digite sua senha',
                            icon: Icons.lock_outline,
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
                              if (value == null || value.isEmpty) {
                                return 'Digite sua senha';
                              }

                              if (!Validators.isValidPassword(value)) {
                                return 'A senha deve ter pelo menos 6 caracteres, um número e um caractere especial';
                              }

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
                                    isScrollControlled:
                                        true, // Permite que o modal suba com o teclado
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
                                onPressed: () {},
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
                          textInputAction: TextInputAction.done,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Digite seu nome';
                            }

                            return null;
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    //button to submit the form
                    SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {}
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
                            child: Text(
                              anonymousEntry ? 'Entrar como Anônimo' : 'Entrar',
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

                    //divider with "OU" text
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

                    //button to toggle anonymous entry
                    OutlinedButton.icon(
                      onPressed: () {
                        setState(() {
                          anonymousEntry = !anonymousEntry;
                        });

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

  //input constructor
  Widget _buildInput({
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    bool obscureText = false,
    Widget? suffixIcon,
    Iterable<String>? autofillHints,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      autofillHints: autofillHints,
      validator: validator,
      style: const TextStyle(fontSize: 15, color: Color(0xFF2D3142)),
      decoration: InputDecoration(
        //color of the label when the field is open!! !!
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
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 16,
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

//class to create a custom clipper for the header image
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
