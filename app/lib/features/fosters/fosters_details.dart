import 'package:flutter/material.dart';
import '../../services/foster_service.dart';
import '../fosters/fosters_register.dart';

const Color _secondary = Color(0xFFE27B1D);
const Color _soft = Color(0x26FFA94D);
const Color _textDark = Color(0xFF2B2B2B);

class FosterDetailsScreen extends StatefulWidget {
  final FosterHome foster;

  const FosterDetailsScreen({super.key, required this.foster});

  @override
  State<FosterDetailsScreen> createState() => _FosterDetailsScreenState();
}

class _FosterDetailsScreenState extends State<FosterDetailsScreen> {
  final _service = FosterService();

  late Future<FosterHome> _future;
  Future<String>? _city;
  Future<String>? _street;

  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<FosterHome> _load() async {
    final id = widget.foster.id;
    if (id == null) throw Exception('Lar sem identificador.');

    final f = await _service.getFosterHome(id);

    if (f.hasLocation) {
      _city = _service.cityFromCoordinates(f.latitude!, f.longitude!);
      _street = _service.streetFromCoordinates(f.latitude!, f.longitude!);
    }

    return f;
  }

  Future<void> _edit(FosterHome full) async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => FosterRegister(foster: full)),
    );

    if (updated == true && mounted) Navigator.pop(context, true);
  }

  Future<void> _delete(FosterHome full) async {
    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        backgroundColor: const Color(0xFFF7E8DF),
        surfaceTintColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 24,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(26),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFE0D8),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.delete_outline_rounded,
                        color: Colors.red,
                        size: 23,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Excluir lar',
                        style: TextStyle(
                          color: _textDark,
                          fontSize: 21,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.72),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: const Color(0xFFE9CFC2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Deseja realmente excluir este lar?',
                        style: TextStyle(
                          color: _textDark,
                          fontSize: 14,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        full.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _secondary,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 9),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.info_outline_rounded,
                            color: Colors.redAccent,
                            size: 17,
                          ),
                          const SizedBox(width: 7),
                          Expanded(
                            child: Text(
                              'Essa ação não pode ser desfeita.',
                              style: TextStyle(
                                color: Colors.red.shade800,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                height: 1.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _secondary,
                          side: const BorderSide(color: _secondary),
                          minimumSize: const Size(0, 44),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(13),
                          ),
                        ),
                        child: const Text('Cancelar'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.pop(ctx, true),
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          size: 18,
                        ),
                        label: const Text('Excluir'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade600,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          minimumSize: const Size(0, 44),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(13),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (confirm != true || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    setState(() => _isDeleting = true);

    try {
      await _service.deleteFosterHome(full.id!);
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Lar excluído com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
         appBar: AppBar( //
        toolbarHeight: 48,
        title: const Text(
          'Detalhes do lar',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: Colors.white,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFFA94D), Color(0xFFFF8C42)],
            ),
          ),
        ),
      ),
      body: FutureBuilder<FosterHome>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(
              child: CircularProgressIndicator(color: _secondary),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      snapshot.error.toString().replaceFirst('Exception: ', ''),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed: () => setState(() => _future = _load()),
                      style: TextButton.styleFrom(foregroundColor: _secondary),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Tentar novamente'),
                    ),
                  ],
                ),
              ),
            );
          }

          return _buildContent(snapshot.data!);
        },
      ),
    );
  }

  Widget _buildContent(FosterHome f) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 650),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cabeçalho
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _soft,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.home_rounded, size: 36, color: _secondary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        f.name,
                        style: const TextStyle(
                          color: _textDark,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (f.capacity != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.pets, size: 14, color: _secondary),
                            const SizedBox(width: 4),
                            Text(
                              '${f.capacity}',
                              style: const TextStyle(
                                color: _textDark,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Localização
              if (f.hasLocation) ...[
                _FutureRow(
                  icon: Icons.location_city_outlined,
                  label: 'Cidade',
                  future: _city!,
                ),
                _FutureRow(
                  icon: Icons.signpost_outlined,
                  label: 'Rua / Avenida',
                  future: _street!,
                ),
                _InfoRow(
                  icon: Icons.my_location,
                  label: 'Coordenadas',
                  text:
                      '${f.latitude!.toStringAsFixed(6)}, '
                      '${f.longitude!.toStringAsFixed(6)}',
                ),
              ],

              if (f.ownerName != null)
                _InfoRow(
                  icon: Icons.person_outline,
                  label: 'Responsável',
                  text: f.ownerEmail != null
                      ? '${f.ownerName}\n${f.ownerEmail}'
                      : f.ownerName!,
                ),
              if (f.formattedPhone != null)
                _InfoRow(
                  icon: Icons.phone_outlined,
                  label: 'Telefone',
                  text: f.formattedPhone!,
                ),
              if (f.email != null)
                _InfoRow(
                  icon: Icons.email_outlined,
                  label: 'E-mail de contato',
                  text: f.email!,
                ),
              if (f.capacity != null)
                _InfoRow(
                  icon: Icons.pets_outlined,
                  label: 'Capacidade',
                  text: '${f.capacity} animais',
                ),
              if (f.userName != null)
                _InfoRow(
                  icon: Icons.badge_outlined,
                  label: 'Cadastrado por',
                  text: f.userName!,
                ),

              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                    height: 48,
                    child: Ink(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFFFFA94D),
                            Color(0xFFFF8C42),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ElevatedButton.icon(
                        onPressed: _isDeleting ? null : () => _edit(f),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          shadowColor: Colors.transparent,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.edit_outlined),
                        label: const Text('Editar'),
                      ),
                    ),
                  ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: OutlinedButton.icon(
                        onPressed: _isDeleting ? null : () => _delete(f),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: _isDeleting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.red,
                                ),
                              )
                            : const Icon(Icons.delete_outline),
                        label: const Text('Excluir'),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
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
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(
              color: _soft,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: _secondary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 2),
                Text(
                  text,
                  style: const TextStyle(
                    fontSize: 15,
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

class _FutureRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Future<String> future;

  const _FutureRow({
    required this.icon,
    required this.label,
    required this.future,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: future,
      builder: (_, snapshot) => _InfoRow(
        icon: icon,
        label: label,
        text: snapshot.connectionState == ConnectionState.done
            ? (snapshot.data ?? 'Indisponível')
            : 'Buscando...',
      ),
    );
  }
}
