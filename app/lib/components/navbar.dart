import 'package:flutter/material.dart';
import '../utils/token_storage.dart';

class NavItem {
  final IconData icon;
  final String route;
  final bool adminOnly;

  const NavItem({
    required this.icon,
    required this.route,
    this.adminOnly = false,
  });
}

class NavbarComponent extends StatefulWidget {
  final int currentIndex;

  const NavbarComponent({super.key, required this.currentIndex});

  @override
  State<NavbarComponent> createState() => _NavbarComponentState();
}

class _NavbarComponentState extends State<NavbarComponent> {
  static const Color navBarColor = Color(0xFFE27B1D);

  bool _isAdmin = false;
  bool _isLoading = true;

  // Definição centralizada de Ícones e Rotas
  final List<NavItem> _allItems = const [
    NavItem(
      icon: Icons.home_outlined,
      route: '/feed',
    ), // Ícone 1 (Índice 0): Feed
    NavItem(
      icon: Icons.pets_outlined,
      route: '/user_pets',
    ), // Ícone 2 (Índice 1): Listagem de Adoção (Usuários)
    NavItem(
      icon: Icons.feedback_outlined,
      route: '/feedback',
    ), // Ícone 3 (Índice 2): Feedback
    NavItem(
      icon: Icons.admin_panel_settings_outlined,
      route: '/admin_pets',
      adminOnly: true,
    ), // Ícone 4 (Índice 3): Painel de Gestão (Exclusivo Admin)
    NavItem(
      icon: Icons.info_outline,
      route: '/info',
    ), // Ícone 5 (Índice 4): Informações
    NavItem(
      icon: Icons.settings_outlined,
      route: '/configuracoes',
    ), // Ícone 6 (Índice 5): Configurações
  ];

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    final isAdmin = await TokenStorage.hasPermission('animal:create');

    if (!mounted) return;

    setState(() {
      _isAdmin = isAdmin;
      _isLoading = false;
    });
  }

  void _navigate(String route) {
    final currentRoute = ModalRoute.of(context)?.settings.name;
    if (currentRoute == route) return; // Evita recarregar a tela atual

    Navigator.pushReplacementNamed(context, route);
  }

  @override
  Widget build(BuildContext context) {
    // Filtra os itens removendo os exclusivos de admin se o usuário for anônimo/USER
    final visibleItems = _allItems
        .where((item) => !item.adminOnly || _isAdmin)
        .toList();

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
          child: _isLoading
              ? const SizedBox()
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: visibleItems.map((item) {
                      final originalIndex = _allItems.indexOf(item);
                      final isSelected = widget.currentIndex == originalIndex;

                      return InkWell(
                        onTap: () => _navigate(item.route),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 22,
                            vertical: 12,
                          ),
                          child: Icon(
                            item.icon,
                            size: 28,
                            color: isSelected
                                ? Colors.white
                                : Colors.white.withOpacity(0.6),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
        ),
      ),
    );
  }
}
