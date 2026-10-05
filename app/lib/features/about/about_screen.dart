import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../components/navbar.dart';

const Color _primary = Color(0xFFFFA94D);
const Color _secondary = Color(0xFFFF8C42);
const Color _darkOrange = Color(0xFFE0641B);
const Color _background = Color(0xFFF8F9FA);

BoxDecoration _card() => BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(20),
  boxShadow: [
    BoxShadow(
      color: Colors.black.withOpacity(0.04),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ],
);

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, -0.4),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: _darkOrange,
          content: Text(message),
          duration: const Duration(seconds: 2),
        ),
      );
  }

  void _copy(String label, String value) {
    Clipboard.setData(ClipboardData(text: value));
    _snack('$label copiado!');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            _buildHeader(),

            // Localização
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.location_on, color: _darkOrange, size: 18),
                SizedBox(width: 4),
                Text(
                  'Encantado, RS',
                  style: TextStyle(
                    fontSize: 16,
                    color: _darkOrange,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const _SupportBadge(),
            const SizedBox(height: 32),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SectionTitle('Sobre Nós'),
                  _buildAboutCard(),
                  const SizedBox(height: 30),
                  const _SectionTitle('Como Ajudar'),
                  _buildHelpGrid(),
                  const SizedBox(height: 30),
                  const _SectionTitle('Contato e Redes'),
                  _buildContactCard(),
                  const SizedBox(height: 28),
                  const Center(
                    child: Text(
                      'Feito com ❤️ em Encantado, RS',
                      style: TextStyle(fontSize: 12, color: Colors.black38),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const NavbarComponent(currentIndex: 7),
    );
  }

  // ---------------------------------------------------------------------------
  // HEADER
  // ---------------------------------------------------------------------------
  Widget _buildHeader() {
    return SizedBox(
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
                  colors: [_primary, _darkOrange],
                ),
              ),
              // Decoração sutil dentro do gradiente
              child: Stack(
                children: [
                  Positioned(top: -50, right: -40, child: _circle(180, 0.10)),
                  Positioned(top: 70, left: -60, child: _circle(150, 0.08)),
                  Positioned(top: 40, right: 28, child: _paw(44, 0.4)),
                  Positioned(top: 120, left: 30, child: _paw(28, -0.5)),
                ],
              ),
            ),
          ),
          Positioned(
            top: 55,
            child: FadeTransition(
              opacity: _fade,
              child: SlideTransition(
                position: _slide,
                child: const Column(
                  children: [
                    Text(
                      'Associação Acolher',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.2,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Resgatar  •  Cuidar  •  Amar',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white70,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
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
                    color: _darkOrange.withOpacity(0.25),
                    blurRadius: 24,
                    spreadRadius: 2,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(70),
                child: Image.asset(
                  'assets/img/image.png',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      const Icon(Icons.pets, size: 56, color: _primary),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _circle(double size, double opacity) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: Colors.white.withOpacity(opacity),
    ),
  );

  Widget _paw(double size, double angle) => Transform.rotate(
    angle: angle,
    child: Icon(Icons.pets, size: size, color: Colors.white.withOpacity(0.16)),
  );

  // ---------------------------------------------------------------------------
  // SOBRE NÓS (texto + citação)
  // ---------------------------------------------------------------------------
  Widget _buildAboutCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: _card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'A Associação Acolher é um refúgio de esperança para animais em situação de abandono na cidade de Encantado, RS. Nossa missão é resgatar, cuidar e encontrar lares cheios de amor para cães e gatos que mais precisam.',
            style: TextStyle(fontSize: 14, height: 1.6, color: Colors.black),
            textAlign: TextAlign.justify,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
              border: const Border(
                left: BorderSide(color: _secondary, width: 4),
              ),
            ),
            child: const Text(
              '"A compaixão pelos animais está intimamente ligada à bondade de caráter, e quem é cruel com os animais não pode ser um bom homem."\n— Arthur Schopenhauer',
              style: TextStyle(
                fontSize: 13,
                height: 1.5,
                fontStyle: FontStyle.italic,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpGrid() {
    final items = [
      (Icons.pets, 'Adotar', 'Dê um lar'),
      (Icons.volunteer_activism, 'Doar', 'Ração e itens'),
      (Icons.people_alt_rounded, 'Voluntariar', 'Doe seu tempo'),
      (Icons.favorite_rounded, 'Apadrinhar', 'Ajude todo mês'),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.25,
      children: [
        for (final (icon, title, subtitle) in items)
          InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => _snack('Em breve: $title 🐾'),
            child: Ink(
              decoration: _card().copyWith(
                border: Border.all(color: _primary.withOpacity(0.35)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: _primary.withOpacity(0.15),
                    child: Icon(icon, color: _darkOrange, size: 24),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 12, color: Colors.black45),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildContactCard() {
    return Container(
      decoration: _card(),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _contactTile(Icons.phone, 'Telefone / WhatsApp', '(51) 9XXXX-XXXX'),
          _contactTile(Icons.camera_alt, 'Instagram', '@associacaoacolher'),
          _contactTile(
            Icons.facebook,
            'Facebook',
            'Associação Acolher',
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _contactTile(
    IconData icon,
    String title,
    String subtitle, {
    bool isLast = false,
  }) {
    return Column(
      children: [
        ListTile(
          onTap: () => _copy(title, subtitle),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 6,
          ),
          leading: CircleAvatar(
            backgroundColor: _primary.withOpacity(0.15),
            child: Icon(icon, color: _secondary, size: 22),
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
          trailing: const Icon(
            Icons.copy_rounded,
            size: 18,
            color: Colors.black26,
          ),
        ),
        if (!isLast)
          Divider(
            height: 1,
            color: Colors.grey.withOpacity(0.1),
            indent: 68,
            endIndent: 20,
          ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 5,
            height: 22,
            decoration: BoxDecoration(
              color: _secondary,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            text,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

// Badge de Apoio
class _SupportBadge extends StatefulWidget {
  const _SupportBadge();

  @override
  State<_SupportBadge> createState() => _SupportBadgeState();
}

class _SupportBadgeState extends State<_SupportBadge> {
  bool _isSupporting = false;

  void _toggleSupport() {
    HapticFeedback.lightImpact();
    setState(() => _isSupporting = !_isSupporting);
    if (_isSupporting) _showThankYouModal(context);
  }

  @override
  Widget build(BuildContext context) {
    final color = _isSupporting ? Colors.red : _darkOrange;

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
            color: _isSupporting ? Colors.red : _primary,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
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
              transitionBuilder: (child, animation) =>
                  ScaleTransition(scale: animation, child: child),
              child: Icon(
                _isSupporting ? Icons.favorite : Icons.favorite_border,
                key: ValueKey<bool>(_isSupporting),
                color: color,
                size: 20,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _isSupporting ? 'Apoiado!' : 'Apoiar Projeto',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: color,
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
    pageBuilder: (_, __, ___) => const Center(child: _ThankYouCard()),
    transitionBuilder: (_, animation, __, child) => FadeTransition(
      opacity: animation,
      child: ScaleTransition(
        scale: CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
        child: child,
      ),
    ),
  );
}

class _ThankYouCard extends StatefulWidget {
  const _ThankYouCard();

  @override
  State<_ThankYouCard> createState() => _ThankYouCardState();
}

class _ThankYouCardState extends State<_ThankYouCard> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 48),
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.favorite, color: Colors.red, size: 40),
            SizedBox(height: 20),
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
