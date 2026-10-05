import 'package:flutter/material.dart';

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

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  static const String _name = 'Caroline Martini';
  static const String _city = 'Relvado, RS';

  final TextEditingController _bioController = TextEditingController();

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
      begin: const Offset(0.15, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _bioController.dispose();
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

  void _saveBio() {
    FocusScope.of(context).unfocus();
    _snack('Sobre mim salvo!');
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: _background,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: Column(
          children: [
            _buildHeader(top),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SectionTitle('Sobre mim'),
                  _buildBioCard(),
                  const SizedBox(height: 28),
                  const _SectionTitle('Informações'),
                  _buildInfoCard(),
                  const SizedBox(height: 28),
                  const _SectionTitle('Fotos'),
                  _buildGallery(),
                  const SizedBox(height: 28),
                  _buildLogoutButton(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(double top) {
    final h = 290 + top;

    return SizedBox(
      height: h * 0.92,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Fundo curvado com gradiente
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: h,
            child: ClipPath(
              clipper: HeaderCurveClipper(),
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [_primary, _darkOrange],
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(top: -60, right: -50, child: _circle(200, 0.10)),
                    Positioned(top: 150, left: -70, child: _circle(160, 0.07)),
                    Positioned(top: top + 140, right: 30, child: _paw(40, 0.4)),
                  ],
                ),
              ),
            ),
          ),

          // Botão voltar (no lugar da AppBar)
          Positioned(
            top: top + 4,
            left: 12,
            child: _roundIcon(
              Icons.arrow_back_ios_new_rounded,
              () => Navigator.maybePop(context),
            ),
          ),

          Positioned(top: top + 64, left: 24, child: _buildAvatar()),

          Positioned(
            top: top + 94,
            left: 152,
            right: 24,
            child: FadeTransition(
              opacity: _fade,
              child: SlideTransition(
                position: _slide,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      _name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          color: Colors.white70,
                          size: 14,
                        ),
                        SizedBox(width: 3),
                        Text(
                          _city,
                          style: TextStyle(fontSize: 13, color: Colors.white70),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        '🐾 Apoiadora do projeto',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 108,
          height: 108,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            border: Border.all(color: Colors.white, width: 4),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipOval(
            child: Container(
              color: _primary.withOpacity(0.18),
              child: const Icon(Icons.person, size: 64, color: _darkOrange),
            ),
          ),
        ),
        Positioned(
          right: 0,
          bottom: 2,
          child: GestureDetector(
            onTap: () => _snack('Trocar foto em breve!'),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: _darkOrange,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(
                Icons.camera_alt,
                size: 14,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _roundIcon(IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.white.withOpacity(0.2),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(9),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
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

  Widget _buildBioCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      decoration: _card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          TextField(
            controller: _bioController,
            minLines: 4,
            maxLines: null,
            maxLength: 300,
            cursorColor: _darkOrange,
            textCapitalization: TextCapitalization.sentences,
            style: const TextStyle(
              fontSize: 14,
              height: 1.6,
              color: Colors.black87,
            ),
            decoration: const InputDecoration(
              border: InputBorder.none,
              hintText: 'Escreva aqui o que quiser sobre você...',
              hintStyle: TextStyle(fontSize: 14, color: Colors.black38),
            ),
          ),
          TextButton.icon(
            onPressed: _saveBio,
            style: TextButton.styleFrom(foregroundColor: _darkOrange),
            icon: const Icon(Icons.check_rounded, size: 18),
            label: const Text(
              'Salvar',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      decoration: _card(),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _infoTile(
            Icons.email_outlined,
            'E-mail',
            'caroline.martini@universo.univates.br',
          ),
          _infoTile(Icons.phone_outlined, 'Telefone', '(51) 9XXXX-XXXX'),
          _infoTile(
            Icons.calendar_month_outlined,
            'Membro desde',
            'Janeiro de 2024',
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _infoTile(
    IconData icon,
    String title,
    String subtitle, {
    bool isLast = false,
  }) {
    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 4,
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

  Widget _buildGallery() {
    return Row(
      children: List.generate(3, (i) {
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i == 2 ? 0 : 10),
            child: AspectRatio(
              aspectRatio: 1,
              child: Container(
                decoration: BoxDecoration(
                  color: _primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _primary.withOpacity(0.35)),
                ),
                child: const Icon(
                  Icons.image_outlined,
                  color: _secondary,
                  size: 32,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton.icon(
        // Volta para a tela de login ('/') limpando o histórico
        onPressed: () =>
            Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.red,
          side: const BorderSide(color: Colors.red, width: 1.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        icon: const Icon(Icons.logout_rounded, size: 20),
        label: const Text(
          'Sair da conta',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
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
