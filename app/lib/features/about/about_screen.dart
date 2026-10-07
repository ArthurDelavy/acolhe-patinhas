import 'package:flutter/material.dart';
import '../../components/navbar.dart'; // Mantenha o caminho original da sua NavbarComponent

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen>
    with SingleTickerProviderStateMixin {
  static const Color primaryColor = Color(0xFFFFA94D);
  static const Color secondaryColor = Color(0xFFFF8C42);
  static const Color darkOrange = Color(0xFFE0641B);
  static const Color backgroundColor = Color(0xFFF8F9FA);

  // Animação de entrada do título
  late final AnimationController _titleController;
  late final Animation<double> _titleFade;
  late final Animation<Offset> _titleSlide;

  @override
  void initState() {
    super.initState();

    _titleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _titleFade = CurvedAnimation(
      parent: _titleController,
      curve: Curves.easeOut,
    );

    _titleSlide = Tween<Offset>(begin: const Offset(0, -0.4), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _titleController, curve: Curves.easeOutCubic),
        );

    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) _titleController.forward();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Curvado e Alongado (ClipPath Original)
            SizedBox(
              height: 360,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.topCenter,
                children: [
                  ClipPath(
                    clipper: HeaderCurveClipper(),
                    child: Container(
                      height: 310,
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [primaryColor, darkOrange],
                        ),
                      ),
                    ),
                  ),

                  Positioned(
                    top: 55,
                    child: FadeTransition(
                      opacity: _titleFade,
                      child: SlideTransition(
                        position: _titleSlide,
                        child: const Text(
                          'Associação Acolher',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Logo circular centralizada sobre a curva
                  Positioned(
                    top: 185,
                    child: Container(
                      width: 135,
                      height: 135,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        border: Border.all(color: Colors.white, width: 4),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.12),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(70),
                        child: Image.asset(
                          'assets/img/image.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Localização
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.location_on, color: darkOrange, size: 18),
                SizedBox(width: 4),
                Text(
                  'Encantado, RS',
                  style: TextStyle(
                    fontSize: 16,
                    color: darkOrange,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Badge de Apoio Bonito, Interativo e Compacto
            const _SupportBadge(),

            const SizedBox(height: 35),

            // Conteúdo Principal
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Seção Sobre Nós em Card Clean
                  const Text(
                    'Sobre Nós',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Text(
                      'A Associação Acolher é um refúgio de esperança para animais em situação de abandono na cidade de Encantado, RS. Nossa missão é resgatar, cuidar e encontrar lares cheios de amor para cães e gatos que mais precisam.\n\n"A compaixão pelos animais está intimamente ligada à bondade de caráter, e quem é cruel com os animais não pode ser um bom homem." — Arthur Schopenhauer',
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.6,
                        color: Colors.black,
                      ),
                      textAlign: TextAlign.justify,
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Seção Contato e Redes
                  const Text(
                    'Contato e Redes',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),

                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildContactTile(
                          icon: Icons.phone,
                          title: 'Telefone / WhatsApp',
                          subtitle: '(51) 9XXXX-XXXX',
                          isLast: false,
                        ),
                        _buildContactTile(
                          icon: Icons.camera_alt,
                          title: 'Instagram',
                          subtitle: '@associacaoacolher',
                          isLast: false,
                        ),
                        _buildContactTile(
                          icon: Icons.facebook,
                          title: 'Facebook',
                          subtitle: 'Associação Acolher',
                          isLast: true,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const NavbarComponent(currentIndex: 7),
    );
  }

  Widget _buildContactTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isLast,
  }) {
    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 6,
          ),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: secondaryColor, size: 22),
          ),
          title: Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black45,
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: const TextStyle(
              fontSize: 15,
              color: Colors.black87,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (!isLast)
          Divider(
            height: 1,
            thickness: 1,
            color: Colors.grey.withOpacity(0.1),
            indent: 68,
            endIndent: 20,
          ),
      ],
    );
  }
}

// Badge de Apoio Compacto e Estilizado
class _SupportBadge extends StatefulWidget {
  const _SupportBadge();

  @override
  State<_SupportBadge> createState() => _SupportBadgeState();
}

class _SupportBadgeState extends State<_SupportBadge> {
  bool _isSupporting = false;

  void _toggleSupport() {
    setState(() {
      _isSupporting = !_isSupporting;
    });

    if (_isSupporting) {
      _showThankYouModal(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggleSupport,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
        decoration: BoxDecoration(
          color: _isSupporting ? Colors.red.withOpacity(0.08) : Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: _isSupporting ? Colors.red : _AboutScreenState.primaryColor,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: _isSupporting
                  ? Colors.red.withOpacity(0.1)
                  : Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return ScaleTransition(scale: animation, child: child);
              },
              child: Icon(
                _isSupporting ? Icons.favorite : Icons.favorite_border,
                key: ValueKey<bool>(_isSupporting),
                color: _isSupporting
                    ? Colors.red
                    : _AboutScreenState.darkOrange,
                size: 20,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _isSupporting ? 'Apoiado!' : 'Apoiar Projeto',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: _isSupporting
                    ? Colors.red
                    : _AboutScreenState.darkOrange,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void _showThankYouModal(BuildContext context) {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Fechar',
    barrierColor: Colors.black.withOpacity(0.35),
    transitionDuration: const Duration(milliseconds: 250),
    pageBuilder: (dialogContext, animation, secondaryAnimation) {
      Future.delayed(const Duration(seconds: 3), () {
        if (Navigator.of(dialogContext).canPop()) {
          Navigator.of(dialogContext).pop();
        }
      });
      return const Center(child: _ThankYouCard());
    },
    transitionBuilder: (dialogContext, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
          child: child,
        ),
      );
    },
  );
}

class _ThankYouCard extends StatelessWidget {
  const _ThankYouCard();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 44),
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.18),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.favorite, color: Colors.red, size: 44),
            SizedBox(height: 16),
            Text(
              'Obrigado pelo carinho! 🐾\nSeu apoio ajuda a mudar uma vida.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Clipper Alongado Curvado Original
class HeaderCurveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height * 0.78);

    path.quadraticBezierTo(
      size.width * 0.5,
      size.height * 1.15,
      size.width,
      size.height * 0.32,
    );

    path.lineTo(size.width, 0);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
