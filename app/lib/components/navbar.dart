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
  bool _showIndicator = true;

  final ScrollController _scrollController = ScrollController();

  final List<NavItem> _allItems = const [
    NavItem(icon: Icons.home_outlined, route: '/feed'),
    NavItem(icon: Icons.campaign_outlined, route: '/report'),
    NavItem(icon: Icons.pets_outlined, route: '/user_pets'),
    NavItem(
      icon: Icons.admin_panel_settings_outlined,
      route: '/admin_pets',
      adminOnly: true,
    ),
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
    if (currentRoute == route) return;

    Navigator.pushReplacementNamed(context, route);
  }

  @override
  Widget build(BuildContext context) {
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
          padding: const EdgeInsets.only(top: 6, bottom: 8, left: 8, right: 8),
          child: _isLoading
              ? const SizedBox(height: 56)
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Visibility(
                      visible: _showIndicator,
                      maintainSize: true,
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
