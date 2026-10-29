import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../components/navbar.dart';
import '../../services/post_service.dart';
import '../../services/profile_service.dart';
import '../../services/reports_service.dart';

enum FeedItemType { REPORT, POST }

class FeedItem {
  final FeedItemType itemType;
  final AnimalReport? report;
  final SocialPost? post;
  final DateTime createdAt;

  FeedItem.fromReport(AnimalReport r)
    : itemType = FeedItemType.REPORT,
      report = r,
      post = null,
      createdAt = r.createdAt ?? DateTime.now();

  FeedItem.fromPost(SocialPost p)
    : itemType = FeedItemType.POST,
      report = null,
      post = p,
      createdAt = p.createdAt;
}

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen>
    with AutomaticKeepAliveClientMixin {
  static const Color primaryColor = Color(0xFFE27B1D);

  late final ProfileService _profileService;
  late final ReportService _reportService;
  late final PostService _postService;

  String? _profileImageUrl;
  bool _isLoadingAvatar = true;

  List<FeedItem> _feedItems = [];
  bool _isLoadingFeed = true;
  String? _errorMessage;

  final _descriptionController = TextEditingController();
  XFile? _selectedImage;
  bool _isExpanded = false;
  bool _isPublishing = false;

  // Garante que o estado seja preservado
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _profileService = ProfileService(baseUrl: 'http://localhost:8080');
    _reportService = ReportService();
    _postService = PostService();
    _loadUserAvatar();
    _loadFeed();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
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

  Future<void> _loadFeed({bool isSilent = false}) async {
    if (!mounted) return;

    if (_feedItems.isEmpty && !isSilent) {
      setState(() {
        _isLoadingFeed = true;
        _errorMessage = null;
      });
    }

    try {
      final results = await Future.wait([
        _reportService.listAll().catchError((_) => <AnimalReport>[]),
        _postService.listAll().catchError((_) => <SocialPost>[]),
      ]);

      final reports = results[0] as List<AnimalReport>;
      final posts = results[1] as List<SocialPost>;

      List<FeedItem> items = [];
      items.addAll(reports.map((r) => FeedItem.fromReport(r)));
      items.addAll(posts.map((p) => FeedItem.fromPost(p)));

      items.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      if (mounted) {
        setState(() {
          _feedItems = items;
          _isLoadingFeed = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          if (_feedItems.isEmpty) _errorMessage = 'Erro ao carregar o feed.';
          _isLoadingFeed = false;
        });
      }
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (image != null) {
      setState(() => _selectedImage = image);
    }
  }

  Future<void> _submitPost() async {
    if (_descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Escreva uma descrição para a sua publicação.'),
        ),
      );
      return;
    }

    setState(() => _isPublishing = true);
    try {
      await _postService.createPost(
        description: _descriptionController.text.trim(),
        imageFile: _selectedImage,
      );

      _descriptionController.clear();
      setState(() {
        _selectedImage = null;
        _isExpanded = false;
      });

      _loadFeed();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao publicar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isPublishing = false);
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
    super.build(context);
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
        onRefresh: _loadFeed,
        color: primaryColor,
        child: Column(
          children: [
            // Caixa de criação de posts no topo
            _buildCreatePostCard(),

            // Conteúdo principal
            Expanded(child: _buildBody()),
          ],
        ),
      ),
      bottomNavigationBar: const NavbarComponent(currentIndex: 0),
    );
  }

  Widget _buildCreatePostCard() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 16,
                backgroundColor: primaryColor,
                child: Icon(Icons.person, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    if (!_isExpanded) setState(() => _isExpanded = true);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _isExpanded
                          ? 'Escrevendo publicação...'
                          : 'Escrever publicação...',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.campaign, color: primaryColor),
                tooltip: 'Reportar Animal',
                onPressed: () =>
                    Navigator.pushNamed(context, '/report').then((_) {
                      _loadFeed(isSilent: true);
                    }),
              ),
            ],
          ),

          if (_isExpanded) ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              style: const TextStyle(fontSize: 12),
              decoration: const InputDecoration(
                hintText: 'No que você está pensando hoje?',
                border: InputBorder.none,
              ),
            ),
            if (_selectedImage != null)
              Stack(
                children: [
                  Container(
                    height: 120,
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: kIsWeb
                          ? Image.network(
                              _selectedImage!.path,
                              fit: BoxFit.cover,
                            )
                          : Image.file(
                              File(_selectedImage!.path),
                              fit: BoxFit.cover,
                            ),
                    ),
                  ),
                  Positioned(
                    right: 6,
                    top: 10,
                    child: InkWell(
                      onTap: () => setState(() => _selectedImage = null),
                      child: const CircleAvatar(
                        radius: 11,
                        backgroundColor: Colors.black54,
                        child: Icon(Icons.close, size: 12, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(
                    Icons.photo_library,
                    color: primaryColor,
                    size: 18,
                  ),
                  label: Text(
                    _selectedImage == null ? 'Anexar Foto' : 'Trocar Foto',
                    style: const TextStyle(color: primaryColor, fontSize: 11),
                  ),
                ),
                Row(
                  children: [
                    TextButton(
                      onPressed: () => setState(() => _isExpanded = false),
                      child: const Text(
                        'Cancelar',
                        style: TextStyle(color: Colors.grey, fontSize: 11),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: _isPublishing ? null : _submitPost,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                      ),
                      child: _isPublishing
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Publicar',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                              ),
                            ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoadingFeed) {
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
                onPressed: _loadFeed,
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

    if (_feedItems.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 100),
          Center(
            child: Column(
              children: [
                Icon(Icons.pets, size: 48, color: Colors.grey),
                SizedBox(height: 12),
                Text(
                  'Nenhuma publicação encontrada ainda.',
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
      itemCount: _feedItems.length,
      itemBuilder: (context, index) {
        final item = _feedItems[index];
        if (item.itemType == FeedItemType.REPORT) {
          return _buildReportCard(item.report!);
        } else {
          return _buildSocialPostCard(item.post!);
        }
      },
    );
  }

  // CARD DE POST SOCIAL (Layout com as exatas propriedades das imagens do seu Card)
  Widget _buildSocialPostCard(SocialPost post) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            dense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 0,
            ),
            leading: const CircleAvatar(
              radius: 16,
              backgroundColor: primaryColor,
              child: Icon(Icons.person, size: 18, color: Colors.white),
            ),
            title: Text(
              post.userName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            subtitle: Text(
              '${post.createdAt.day.toString().padLeft(2, '0')}/${post.createdAt.month.toString().padLeft(2, '0')}/${post.createdAt.year}',
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ),
          if (post.imageUrl != null && post.imageUrl!.isNotEmpty)
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxHeight: 320),
              color: primaryColor.withAlpha(20),
              child: Image.network(
                post.imageUrl!,
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
            ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              post.description,
              style: const TextStyle(fontSize: 13, color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }

  // CARD DE REPORTE (EXATAMENTE IGUAL AO SEU CÓDIGO FORNECIDO)
  Widget _buildReportCard(AnimalReport report) {
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
