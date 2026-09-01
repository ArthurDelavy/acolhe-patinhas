import 'package:flutter/material.dart';

class NavbarComponent extends StatelessWidget {
  final int currentIndex;

  const NavbarComponent({super.key, required this.currentIndex});

  static const Color navBarColor = Color(0xFFE27B1D);

  final List<IconData> _navIcons = const [
    Icons.home_outlined, // Índice 0: Feed
    Icons.handshake_outlined, // Índice 1
    Icons.feedback_outlined, // Índice 2
    Icons.pets_outlined, // Índice 3: Cadastro Pets
    Icons.info_outline, // Índice 4
    Icons.settings_outlined, // Índice 5
  ];

  final List<String> _routes = const [
    //trocar caso necessário!
    '/feed',
    '/parcerias',
    '/feedback',
    '/registerPets',
    '/info',
    '/configuracoes',
  ];

  void _navigate(BuildContext context, int index) {
    if (index == currentIndex) return; // Evita recarregar a tela atual

    Navigator.pushReplacementNamed(context, _routes[index]);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: navBarColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: List.generate(_navIcons.length, (index) {
                final isSelected = currentIndex == index;
                return InkWell(
                  onTap: () => _navigate(context, index),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 12,
                    ),
                    child: Icon(
                      _navIcons[index],
                      size: 28,
                      color: isSelected
                          ? Colors.white
                          : Colors.white.withOpacity(0.6),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
