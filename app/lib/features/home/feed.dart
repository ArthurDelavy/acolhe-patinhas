import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../components/navbar.dart';
import '../../services/profile_service.dart';
import '../../services/reports_service.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  static const Color primaryColor = Color(0xFFE27B1D);

  late final ProfileService _profileService;
  late final ReportService _reportService;

  String? _profileImageUrl;
  bool _isLoadingAvatar = true;

  List<AnimalReport> _reports = [];
  bool _isLoadingReports = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _profileService = ProfileService(baseUrl: 'http://localhost:8080');
    _reportService = ReportService();
    _loadUserAvatar();
    _loadReports();
  }

  Future<void> _loadUserAvatar() async {
    try {
      final profile = await _profileService.getProfile();
      if (mounted) {
        setState(() {
          _profileImageUrl = profile.profileImageUrl;
          _isLoadingAvatar = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingAvatar = false);
      }
    }
  }

  Future<void> _loadReports() async {
    setState(() {
      _isLoadingReports = true;
      _errorMessage = null;
    });

    try {
      final reports = await _reportService.listAll();
      if (mounted) {
        setState(() {
          _reports = reports.reversed.toList();
          _isLoadingReports = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
          _isLoadingReports = false;
        });
      }
    }
  }

  void _openProfile() {
    Navigator.pushNamed(context, '/profile').then((_) => _loadUserAvatar());
  }

  Future<void> _openMap(double lat, double lng) async {
    final googleMapsUrl = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
    );
    if (await canLaunchUrl(googleMapsUrl)) {
      await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível abrir o mapa.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 48,
        title: const Text(
          'Meu Feed',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: InkWell(
              onTap: _openProfile,
              customBorder: const CircleBorder(),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: Colors.white,
                child: _isLoadingAvatar
                    ? const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: primaryColor,
                        ),
                      )
                    : ClipOval(
                        child:
                            _profileImageUrl != null &&
                                _profileImageUrl!.isNotEmpty
                            ? Image.network(
                                _profileImageUrl!,
                                width: 32,
                                height: 32,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(
                                      Icons.person,
                                      size: 20,
                                      color: primaryColor,
                                    ),
                              )
                            : const Icon(
                                Icons.person,
                                size: 20,
                                color: primaryColor,
                              ),
                      ),
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadReports,
        color: primaryColor,
        child: _buildBody(),
      ),
      bottomNavigationBar: const NavbarComponent(currentIndex: 0),
    );
  }

  Widget _buildBody() {
    if (_isLoadingReports) {
      return const Center(
        child: CircularProgressIndicator(color: primaryColor),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text(_errorMessage!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadReports,
                style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
                child: const Text(
                  'Tentar Novamente',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_reports.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 100),
          Center(
            child: Column(
              children: [
                Icon(Icons.pets, size: 48, color: Colors.grey),
                SizedBox(height: 12),
                Text(
                  'Nenhum reporte encontrado ainda.',
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      itemCount: _reports.length,
      itemBuilder: (context, index) {
        return _buildPostCard(_reports[index]);
      },
    );
  }

  Widget _buildPostCard(AnimalReport report) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Cabeçalho Compacto (Avatar + Nome + Badge)
          ListTile(
            dense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 0,
            ),
            leading: CircleAvatar(
              radius: 16,
              backgroundColor: primaryColor.withAlpha(40),
              backgroundImage:
                  report.userPhotoUrl != null && report.userPhotoUrl!.isNotEmpty
                  ? NetworkImage(report.userPhotoUrl!)
                  : null,
              child: report.userPhotoUrl == null || report.userPhotoUrl!.isEmpty
                  ? const Icon(Icons.person, size: 18, color: primaryColor)
                  : null,
            ),
            title: Text(
              report.userName ?? 'Usuário Anônimo',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            subtitle: Text(
              report.createdAt != null
                  ? '${report.createdAt!.day.toString().padLeft(2, '0')}/${report.createdAt!.month.toString().padLeft(2, '0')}/${report.createdAt!.year}'
                  : 'Recently',
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _getTypeColor(report.type).withAlpha(25),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _getTypeColor(report.type),
                  width: 0.8,
                ),
              ),
              child: Text(
                report.type.label,
                style: TextStyle(
                  color: _getTypeColor(report.type),
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ),
          ),

          if (report.imageUrl != null && report.imageUrl!.isNotEmpty)
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxHeight: 320),
              color: primaryColor.withAlpha(20),
              child: Image.network(
                report.imageUrl!,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.medium,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 140,
                  color: Colors.grey[200],
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.broken_image, size: 36, color: Colors.grey),
                      SizedBox(height: 4),
                      Text(
                        'Imagem indisponível',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            Container(
              height: 80,
              color: Colors.orange.withAlpha(15),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.pets, size: 28, color: primaryColor),
                  SizedBox(height: 4),
                  Text(
                    'Reporte sem foto',
                    style: TextStyle(
                      color: primaryColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

          // 3. Conteúdo (Título + Descrição)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  report.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  report.description,
                  style: const TextStyle(fontSize: 13, color: Colors.black),
                ),
                const SizedBox(height: 10),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.location_on,
                      size: 14,
                      color: primaryColor,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: FutureBuilder<String>(
                        future: report.fetchAddress(),
                        builder: (context, snapshot) {
                          return Text(
                            snapshot.data ?? 'Buscando endereço...',
                            style: const TextStyle(
                              fontSize: 10.5,
                              color: Colors.grey,
                              height: 1.1,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () => _openMap(report.latitude, report.longitude),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.map, size: 13, color: primaryColor),
                            SizedBox(width: 3),
                            Text(
                              'Ver no mapa',
                              style: TextStyle(
                                color: primaryColor,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getTypeColor(ReportType type) {
    switch (type) {
      case ReportType.LOST:
        return Colors.red;
      case ReportType.FOUND:
        return Colors.green;
      case ReportType.ABANDONED:
        return Colors.orange;
    }
  }
}
