import 'package:flutter/material.dart';
import '../../components/navbar.dart';
import '../../services/foster_service.dart';
import '../../utils/token_storage.dart';
import '../fosters/fosters_details.dart';
import '../fosters/fosters_register.dart';

const Color _primary = Color(0xFFFFA94D);
const Color _secondary = Color(0xFFE27B1D);
const Color _soft = Color(0x26FFA94D);
const Color _background = Colors.white;
const Color _textDark = Color(0xFF2B2B2B);

class FostersScreen extends StatefulWidget {
  const FostersScreen({super.key});

  @override
  State<FostersScreen> createState() => _FostersScreenState();
}

class _FostersScreenState extends State<FostersScreen> {
  final _service = FosterService();

  late Future<List<FosterHome>> _fosters;
  bool _canCreate = false;

  @override
  void initState() {
    super.initState();
    _fosters = _service.listFosterHomes();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    final allowed = await TokenStorage.hasPermission('fosterhome:create');
    if (!mounted) return;
    setState(() => _canCreate = allowed);
  }

  Future<void> _reload() async {
    setState(() {
      _fosters = _service.listFosterHomes();
    });
  }

  Future<void> _openRegister() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const FosterRegister()),
    );

    if (result == true && mounted) {
      _reload();
    }
  }

  Future<void> _openDetails(FosterHome foster) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => FosterDetailsScreen(foster: foster)),
    );

    if (result == true && mounted) {
      _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        toolbarHeight: 48,
        title: const Text('Lares parceiros', style: TextStyle(fontSize: 16)),
        backgroundColor: _secondary,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<FosterHome>>(
        future: _fosters,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(
              child: CircularProgressIndicator(color: _secondary),
            );
          }

          if (snapshot.hasError) {
            return _MessageView(
              icon: Icons.error_outline,
              message: snapshot.error.toString().replaceFirst(
                'Exception: ',
                '',
              ),
              onRetry: _reload,
            );
          }

          final fosters = snapshot.data ?? [];

          if (fosters.isEmpty) {
            return _MessageView(
              icon: Icons.home_outlined,
              message: 'Nenhum lar temporário cadastrado.',
              onRetry: _reload,
            );
          }

          return RefreshIndicator(
            color: _secondary,
            onRefresh: _reload,
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              itemCount: fosters.length,
              itemBuilder: (_, i) => Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 650),
                  child: _FosterCard(
                    foster: fosters[i],
                    onTap: () => _openDetails(fosters[i]),
                  ),
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButton: _canCreate
          ? FloatingActionButton.extended(
              onPressed: _openRegister,
              backgroundColor: _secondary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('Cadastrar lar temporário'),
            )
          : null,
      bottomNavigationBar: const NavbarComponent(currentIndex: 0),
    );
  }
}

class _FosterCard extends StatelessWidget {
  final FosterHome foster;
  final VoidCallback onTap;

  const _FosterCard({required this.foster, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _secondary.withOpacity(0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: _soft, width: 1.5),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: _soft,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.home_rounded,
                    color: _secondary,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),

                // Informações centrais
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        foster.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _textDark,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      if (foster.ownerName != null)
                        Row(
                          children: [
                            const Icon(
                              Icons.person_outline,
                              size: 16,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                foster.ownerName!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      if (foster.capacity != null) ...[
                        const SizedBox(height: 10),
                        // Chip de capacidade
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _background,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: _soft, width: 1.5),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.pets,
                                size: 12,
                                color: _secondary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Vagas: ${foster.capacity}',
                                style: const TextStyle(
                                  color: _secondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: _soft,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: _secondary,
                    size: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MessageView extends StatelessWidget {
  final IconData icon;
  final String message;
  final Future<void> Function() onRetry;

  const _MessageView({
    required this.icon,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: _primary),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: onRetry,
              style: TextButton.styleFrom(foregroundColor: _secondary),
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }
}
