import 'package:flutter/material.dart';
import '../../components/navbar.dart';
import '../../services/foster_service.dart';
import '../../utils/token_storage.dart';
import '../fosters/fosters_register.dart';

const Color _primary = Color(0xFFFFA94D);
const Color _secondary = Color(0xFFFF8C42);
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
    final future = _service.listFosterHomes();
    setState(() => _fosters = future);
    await future.catchError((_) => <FosterHome>[]);
  }

  Future<void> _openRegister() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const FosterRegister()),
    );

    if (created == true && mounted) _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        toolbarHeight: 48,
        title: const Text('Lares parceiros', style: TextStyle(fontSize: 16)),
        backgroundColor: _primary,
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
                  child: _FosterCard(foster: fosters[i], service: _service),
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

// ---------------------------------------------------------------------------
// Card
// ---------------------------------------------------------------------------
class _FosterCard extends StatelessWidget {
  final FosterHome foster;
  final FosterService service;

  const _FosterCard({required this.foster, required this.service});

  /// 51937294406 -> (51) 93729-4406
  String _formatPhone(String phone) {
    final d = phone.replaceAll(RegExp(r'\D'), '');
    if (d.length != 11) return phone;
    return '(${d.substring(0, 2)}) ${d.substring(2, 7)}-${d.substring(7)}';
  }

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[
      if (foster.hasLocation)
        _CityRow(
          service: service,
          latitude: foster.latitude!,
          longitude: foster.longitude!,
        ),
      if (foster.ownerName != null)
        _InfoRow(
          icon: Icons.person_outline,
          label: 'Responsável',
          text: foster.ownerName!,
        ),
      if (foster.phoneNumber != null)
        _InfoRow(
          icon: Icons.phone_outlined,
          label: 'Telefone',
          text: _formatPhone(foster.phoneNumber!),
        ),
      if (foster.email != null)
        _InfoRow(
          icon: Icons.email_outlined,
          label: 'E-mail',
          text: foster.email!,
        ),
      if (foster.userName != null)
        _InfoRow(
          icon: Icons.badge_outlined,
          label: 'Cadastrado por',
          text: foster.userName!,
        ),
    ];

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEEEEE)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 5, color: _primary), // faixa lateral
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(
                            color: _soft,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.home_rounded,
                            color: _secondary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            foster.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: _textDark,
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (foster.capacity != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: _soft,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.pets,
                                  size: 14,
                                  color: _secondary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${foster.capacity}',
                                  style: const TextStyle(
                                    color: _textDark,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (rows.isNotEmpty) ...[
                      const Divider(height: 24),
                      ...rows,
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String text;

  const _InfoRow({required this.icon, required this.label, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: _secondary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
                Text(
                  text,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _textDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Busca a cidade uma única vez (não refaz a requisição a cada rebuild).
class _CityRow extends StatefulWidget {
  final FosterService service;
  final double latitude;
  final double longitude;

  const _CityRow({
    required this.service,
    required this.latitude,
    required this.longitude,
  });

  @override
  State<_CityRow> createState() => _CityRowState();
}

class _CityRowState extends State<_CityRow> {
  late final Future<String> _city;

  @override
  void initState() {
    super.initState();
    _city = widget.service.cityFromCoordinates(
      widget.latitude,
      widget.longitude,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _city,
      builder: (_, snapshot) => _InfoRow(
        icon: Icons.location_on_outlined,
        label: 'Localização',
        text: snapshot.connectionState == ConnectionState.done
            ? (snapshot.data ?? 'Localização indisponível')
            : 'Buscando localização...',
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
