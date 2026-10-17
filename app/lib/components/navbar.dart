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
  bool _showIndicator = true; // Controla se a setinha aparece

  final ScrollController _scrollController = ScrollController();

  final List<NavItem> _allItems = const [
    NavItem(icon: Icons.home_outlined, route: '/feed'),
    NavItem(icon: Icons.pets_outlined, route: '/user_pets'),
    NavItem(icon: Icons.feedback_outlined, route: '/feedback'),
    NavItem(
      icon: Icons.admin_panel_settings_outlined,
      route: '/admin_pets',
      adminOnly: true,
    ),

    NavItem(icon: Icons.info_outline, route: '/info'),
    NavItem(icon: Icons.settings_outlined, route: '/configuracoes'),
    NavItem(
      icon: Icons.volunteer_activism_outlined,
      route: '/fosters',
      adminOnly: true,
    ),
    NavItem(icon: Icons.badge_outlined, route: '/about-profile'),
  ];

  @override
  void initState() {
    super.initState();
    _checkPermission();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 10) {
        if (_showIndicator) setState(() => _showIndicator = false);
      } else {
        if (!_showIndicator) setState(() => _showIndicator = true);
      }
    });

    // Verifica após renderizar a tela se há necessidade de scroll
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients &&
          _scrollController.position.maxScrollExtent <= 0) {
        setState(() => _showIndicator = false);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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
          // O height fixo foi removido para acomodar o texto em cima sem amassar os botões
          padding: const EdgeInsets.only(top: 6, bottom: 8, left: 8, right: 8),
          child: _isLoading
              ? const SizedBox(height: 56) // Altura temporária no loading
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Indicativo de Deslize (Fica em cima, à direita)
                    Visibility(
                      visible: _showIndicator,
                      maintainSize:
                          true, // Mantém o espaço para a barra não pular
                      maintainAnimation: true,
                      maintainState: true,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 12, bottom: 2),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Deslize',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 2),
                            Icon(
                              Icons.arrow_forward,
                              color: Colors.white.withOpacity(0.9),
                              size: 12,
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Lista rolável de botões
                    SingleChildScrollView(
                      controller: _scrollController,
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: visibleItems.map((item) {
                          final originalIndex = _allItems.indexOf(item);
                          final isSelected =
                              widget.currentIndex == originalIndex;

                          return InkWell(
                            onTap: () => _navigate(item.route),
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 22,
                                vertical: 10,
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
                  ],
                ),
        ),
      ),
    );
  }
}
