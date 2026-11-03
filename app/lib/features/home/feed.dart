import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../components/navbar.dart';
import '../../services/post_service.dart';
import '../../services/profile_service.dart';
import '../../services/reports_service.dart';

//type of content presented in the feed / post or report
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

  //API services
  late final ProfileService _profileService;
  late final ReportService _reportService;
  late final PostService _postService;

  //logged-in user data
  String? _profileImageUrl;
  int? _currentUserId;
  bool _isAdmin = false;
  bool _isLoadingAvatar = true;

  List<FeedItem> _feedItems = [];
  bool _isLoadingFeed = true;
  String? _errorMessage;

  //pagination state
  int _currentPage = 0;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  final ScrollController _scrollController = ScrollController();

  final _descriptionController = TextEditingController();
  XFile? _selectedImage;
  bool _isExpanded = false;
  bool _isPublishing = false;

  // Keeps the screen active when switching tabs in the navigation bar
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _profileService = ProfileService(
      baseUrl: 'https://acolhe-patinhas.duckdns.org/api',
    );
    _reportService = ReportService();
    _postService = PostService();
    _scrollController.addListener(_onScroll);

    _loadUserAvatarAndInfo();
    _loadFeed();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  /// When the scroll goes past 80% of the list it loads more posts.
  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      if (!_isLoadingMore && _hasMore && !_isLoadingFeed) {
        _loadMoreItems();
      }
    }
  }

  //function to load the user avatar and info from the profile service
  Future<void> _loadUserAvatarAndInfo() async {
    try {
      final profile = await _profileService.getProfile();
      if (mounted) {
        setState(() {
          _profileImageUrl = profile.profileImageUrl;
          _currentUserId = profile.id;
          _isAdmin = profile.role == 'ADMIN';
          _isLoadingAvatar = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingAvatar = false);
      }
    }
  }

  // Loads reports + posts
  Future<void> _loadFeed({bool isSilent = false}) async {
    if (!mounted) return;
    if (_feedItems.isEmpty && !isSilent) {
      setState(() {
        _isLoadingFeed = true;
        _errorMessage = null;
      });
    }

    _currentPage = 0;
    _hasMore = true;

    try {
      // Fetches reports and posts in paralle
      final results = await Future.wait([
        _reportService.listAll().catchError((_) => <AnimalReport>[]),
        _postService
            .listAll(page: 0, size: 20)
            .catchError((_) => <SocialPost>[]),
      ]);

      final reports = results[0] as List<AnimalReport>;
      final posts = results[1] as List<SocialPost>;

      // Fewer than 20 posts = no next page
      if (posts.length < 20) {
        _hasMore = false;
      }

      final openReports = reports.where((r) {
        final statusStr = r.status.name.toUpperCase();
        return statusStr == 'OPEN';
      }).toList();

      List<FeedItem> items = [];
      items.addAll(openReports.map((r) => FeedItem.fromReport(r)));
      items.addAll(posts.map((p) => FeedItem.fromPost(p)));

      // Newest first
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

  //function to load more items when the user scrolls down
  Future<void> _loadMoreItems() async {
    if (_isLoadingMore || !_hasMore) return;
    setState(() => _isLoadingMore = true);

    try {
      final nextPage = _currentPage + 1;
      final newPosts = await _postService.listAll(page: nextPage, size: 20);

      if (newPosts.isEmpty || newPosts.length < 20) {
        _hasMore = false;
      }

      if (newPosts.isNotEmpty) {
        _currentPage = nextPage;
        final newItems = newPosts.map((p) => FeedItem.fromPost(p)).toList();

        setState(() {
          _feedItems.addAll(newItems);
        });
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  //function to pick an image from the gallery using the image_picker package
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

  //function to submit a new post using the PostService
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

      // Refresh the feed after publishing
      _loadFeed(isSilent: true);
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

  //function to delete a post using the PostService
  Future<void> _deletePost(SocialPost post) async {
    final confirm = await _showStyledDeleteDialog(
      title: 'Excluir Publicação',
      message: 'Tem certeza de que deseja remover esta publicação?',
    );

    if (confirm == true) {
      try {
        await _postService.deletePost(post.id);
        setState(() {
          _feedItems.removeWhere((item) => item.post?.id == post.id);
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Publicação removida com sucesso.')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao remover: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  //function to delete a report using the ReportService
  Future<void> _deleteReport(AnimalReport report) async {
    final confirm = await _showStyledDeleteDialog(
      title: 'Excluir Reporte',
      message: 'Tem certeza de que deseja remover este reporte de animal?',
    );

    if (confirm == true && report.id != null) {
      try {
        await _reportService.deleteReport(report.id!);
        setState(() {
          _feedItems.removeWhere((item) => item.report?.id == report.id);
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Reporte removido com sucesso.')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao remover reporte: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  // Deletion confirmation dialog
  Future<bool?> _showStyledDeleteDialog({
    required String title,
    required String message,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
          contentPadding: const EdgeInsets.symmetric(horizontal: 24),
          actionsPadding: const EdgeInsets.all(16),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          content: SizedBox(
            width: MediaQuery.of(context).size.width.clamp(280, 360),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 6),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Voltar', style: TextStyle(color: Colors.grey)),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text(
                'Excluir',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  // Dialog for changing the status of a report (Resolved or Cancelled).
  void _showUpdateStatusDialog(AnimalReport report) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
          contentPadding: const EdgeInsets.symmetric(horizontal: 24),
          actionsPadding: const EdgeInsets.all(16),
          title: const Text(
            'Alterar Status do Reporte',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          content: SizedBox(
            width: MediaQuery.of(context).size.width.clamp(280, 360),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 6),
                Text(
                  'Selecione a nova situação para este reporte. Ao marcar como Resolvido ou Cancelado, ele deixará de ser exibido no feed público.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Voltar', style: TextStyle(color: Colors.grey)),
            ),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red.shade700,
                side: BorderSide(color: Colors.red.shade300),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () => _changeStatus(report, 'CANCELLED', ctx),
              child: const Text('Cancelar Reporte'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () => _changeStatus(report, 'RESOLVED', ctx),
              child: const Text('Resolvido'),
            ),
          ],
        );
      },
    );
  }

  //Sends the new status to the API. If it is RESOLVED/CANCELLED
  Future<void> _changeStatus(
    AnimalReport report,
    String status,
    BuildContext dialogContext,
  ) async {
    Navigator.pop(dialogContext);
    try {
      await _reportService.updateReportStatus(
        reportId: report.id!,
        status: status,
      );

      if (status == 'RESOLVED' || status == 'CANCELLED') {
        setState(() {
          _feedItems.removeWhere((item) => item.report?.id == report.id);
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Status alterado para $status com sucesso.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao atualizar status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  //edit post modal bottom sheet
  void _showEditPostModal(SocialPost post) {
    final editController = TextEditingController(text: post.description);
    XFile? newImage;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Editar Publicação',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: editController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Digite a nova descrição...',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton.icon(
                        onPressed: () async {
                          final img = await ImagePicker().pickImage(
                            source: ImageSource.gallery,
                            imageQuality: 80,
                          );
                          if (img != null) {
                            setModalState(() => newImage = img);
                          }
                        },
                        icon: const Icon(
                          Icons.photo_library,
                          color: primaryColor,
                        ),
                        label: Text(
                          newImage != null
                              ? 'Trocar Imagem'
                              : 'Anexar Nova Foto',
                          style: const TextStyle(color: primaryColor),
                        ),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                        ),
                        onPressed: () async {
                          if (editController.text.trim().isEmpty) return;
                          Navigator.pop(ctx);
                          try {
                            await _postService.updatePost(
                              postId: post.id,
                              description: editController.text.trim(),
                              imageFile: newImage,
                            );
                            _loadFeed(isSilent: true);
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Erro ao atualizar: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                        child: const Text(
                          'Salvar',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Opens the profile screen and refreshes the avatar and info when returning.
  void _openProfile() {
    Navigator.pushNamed(
      context,
      '/profile',
    ).then((_) => _loadUserAvatarAndInfo());
  }

  // Opens Google Maps with the given latitude and longitude.
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

  // Color constants for text and lines
  static const Color _textDark = Color(0xFF1F1F1F);
  static const Color _textSoft = Color(0xFF8A8A8A);
  static const Color _line = Color(0xFFEFEFEF);

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F6F4),
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
        onRefresh: () => _loadFeed(isSilent: false),
        color: primaryColor,
        child: Column(
          children: [
            if (_isAdmin) _buildCreatePostCard(),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
      bottomNavigationBar: const NavbarComponent(currentIndex: 0),
    );
  }

  // Builds a circular avatar with an optional gradient ring.
  Widget _buildAvatar(String? url, {double size = 36, bool ring = true}) {
    final hasUrl = url != null && url.trim().isNotEmpty && url != 'null';
    final inner = ClipOval(
      child: Container(
        width: size,
        height: size,
        color: primaryColor.withOpacity(0.1),
        child: hasUrl
            ? Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    Icon(Icons.person, size: size * 0.55, color: primaryColor),
              )
            : Icon(Icons.person, size: size * 0.55, color: primaryColor),
      ),
    );

    if (!ring) return inner;

    return Container(
      padding: const EdgeInsets.all(2),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [Color(0xFFF5B84A), primaryColor, Color(0xFFD4501A)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: inner,
      ),
    );
  }

  //converts a DateTime to a human-readable "time ago" format
  String _timeAgo(DateTime? date) {
    if (date == null) return 'Recente';
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'Agora';
    if (diff.inMinutes < 60) return 'há ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'há ${diff.inHours} h';
    if (diff.inDays < 7) return 'há ${diff.inDays} d';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  // Builds the card for creating a new post, which expands when tapped.
  Widget _buildCreatePostCard() {
    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      alignment: Alignment.topCenter,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(14, 12, 8, 10),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(bottom: BorderSide(color: _line)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildAvatar(_profileImageUrl, size: 34, ring: false),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      if (!_isExpanded) setState(() => _isExpanded = true);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Text(
                        _isExpanded
                            ? 'Escrevendo publicação...'
                            : 'Escrever publicação...',
                        style: const TextStyle(color: _textSoft, fontSize: 13),
                      ),
                    ),
                  ),
                ),
                // Shortcut to the report animal screen
                IconButton(
                  icon: const Icon(
                    Icons.campaign_outlined,
                    color: primaryColor,
                  ),
                  tooltip: 'Reportar Animal',
                  onPressed: () => Navigator.pushNamed(
                    context,
                    '/report',
                  ).then((_) => _loadFeed(isSilent: true)),
                ),
              ],
            ),
            if (_isExpanded) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: TextField(
                  controller: _descriptionController,
                  maxLines: 3,
                  style: const TextStyle(fontSize: 13.5),
                  decoration: const InputDecoration(
                    hintText: 'No que você está pensando hoje?',
                    hintStyle: TextStyle(color: _textSoft),
                    border: InputBorder.none,
                  ),
                ),
              ),

              // Preview of the chosen photo
              if (_selectedImage != null)
                Padding(
                  padding: const EdgeInsets.only(right: 6, bottom: 8),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: SizedBox(
                          height: 160,
                          width: double.infinity,
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
                        right: 8,
                        top: 8,
                        child: InkWell(
                          onTap: () => setState(() => _selectedImage = null),
                          child: const CircleAvatar(
                            radius: 12,
                            backgroundColor: Colors.black54,
                            child: Icon(
                              Icons.close,
                              size: 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(
                      Icons.photo_library_outlined,
                      color: primaryColor,
                      size: 20,
                    ),
                    label: Text(
                      _selectedImage == null ? 'Anexar foto' : 'Trocar foto',
                      style: const TextStyle(
                        color: primaryColor,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () => setState(() => _isExpanded = false),
                        child: const Text(
                          'Cancelar',
                          style: TextStyle(color: _textSoft, fontSize: 12.5),
                        ),
                      ),
                      const SizedBox(width: 4),
                      FilledButton(
                        onPressed: _isPublishing ? null : _submitPost,
                        style: FilledButton.styleFrom(
                          backgroundColor: primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
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
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
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
              Icon(Icons.error_outline, size: 48, color: Colors.red.shade400),
              const SizedBox(height: 12),
              Text(_errorMessage!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => _loadFeed(isSilent: false),
                style: FilledButton.styleFrom(
                  backgroundColor: primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text('Tentar Novamente'),
              ),
            ],
          ),
        ),
      );
    }

    if (_feedItems.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 100),
          Center(
            child: Column(
              children: [
                Icon(Icons.pets, size: 48, color: Color(0xFFCFCFCF)),
                SizedBox(height: 12),
                Text(
                  'Nenhuma publicação encontrada ainda.',
                  style: TextStyle(color: _textSoft, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      );
    }

    //building the feed list
    return ListView.builder(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      itemCount: _feedItems.length + (_isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _feedItems.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: CircularProgressIndicator(
                color: primaryColor,
                strokeWidth: 2,
              ),
            ),
          );
        }

        final item = _feedItems[index];
        if (item.itemType == FeedItemType.REPORT) {
          return _buildReportCard(item.report!);
        } else {
          return _buildSocialPostCard(item.post!);
        }
      },
    );
  }

  Widget _buildItemHeader({
    required String? avatarUrl,
    required String name,
    required String subtitle,
    Widget? trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
      child: Row(
        children: [
          _buildAvatar(avatarUrl, size: 34),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                    color: _textDark,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 11.5, color: _textSoft),
                ),
              ],
            ),
          ),
          if (trailing != null) trailing else const SizedBox(width: 8),
        ],
      ),
    );
  }

  //menu for editing or deleting a post/report
  Widget _buildOptionsMenu({
    required String editLabel,
    required VoidCallback onEdit,
    required VoidCallback onDelete,
  }) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_horiz, size: 22, color: _textDark),
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      onSelected: (value) {
        if (value == 'edit') {
          onEdit();
        } else if (value == 'delete') {
          onDelete();
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              const Icon(Icons.edit_outlined, size: 18, color: primaryColor),
              const SizedBox(width: 10),
              Text(editLabel, style: const TextStyle(fontSize: 13)),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_outline, size: 18, color: Colors.red),
              SizedBox(width: 10),
              Text(
                'Excluir',
                style: TextStyle(color: Colors.red, fontSize: 13),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMedia(String url) {
    return AspectRatio(
      aspectRatio: 5 / 4,
      child: Image.network(
        url,
        width: double.infinity,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.medium,
        loadingBuilder: (context, child, progress) => progress == null
            ? child
            : Container(color: const Color(0xFFF5F5F5)),
        errorBuilder: (context, error, stackTrace) => Container(
          color: const Color(0xFFF5F5F5),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.broken_image_outlined, size: 36, color: _textSoft),
              SizedBox(height: 4),
              Text(
                'Imagem indisponível',
                style: TextStyle(color: _textSoft, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  //card for a social post, with options to edit or delete if the user is the owner or an admin
  Widget _buildSocialPostCard(SocialPost post) {
    final bool canEditOrDelete =
        _isAdmin || (_currentUserId != null && _currentUserId == post.userId);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _line),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildItemHeader(
            avatarUrl: post.userPhotoUrl,
            name: post.userName,
            subtitle: _timeAgo(post.createdAt),
            trailing: canEditOrDelete
                ? _buildOptionsMenu(
                    editLabel: 'Editar',
                    onEdit: () => _showEditPostModal(post),
                    onDelete: () => _deletePost(post),
                  )
                : null,
          ),
          if (post.imageUrl != null && post.imageUrl!.isNotEmpty)
            _buildMedia(post.imageUrl!),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 16),
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 13.5,
                  height: 1.4,
                  color: _textDark,
                ),
                children: [
                  TextSpan(
                    text: '${post.userName}  ',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  TextSpan(text: post.description),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  //card for an animal report, with options to change status or delete if the user is the owner or an admin
  Widget _buildReportCard(AnimalReport report) {
    final bool isOwner =
        _currentUserId != null &&
        report.userId != null &&
        _currentUserId.toString() == report.userId.toString();

    final bool canManageReport = _isAdmin || isOwner;

    final String? avatarUrl =
        (report.userPhotoUrl != null &&
            report.userPhotoUrl!.trim().isNotEmpty &&
            report.userPhotoUrl != 'null')
        ? report.userPhotoUrl
        : (isOwner ? _profileImageUrl : null);

    final typeColor = _getTypeColor(report.type);
    final hasImage = report.imageUrl != null && report.imageUrl!.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _line),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildItemHeader(
            avatarUrl: avatarUrl,
            name: report.userName ?? 'Usuário Anônimo',
            subtitle: _timeAgo(report.createdAt),
            trailing: canManageReport
                ? _buildOptionsMenu(
                    editLabel: 'Alterar Status',
                    onEdit: () => _showUpdateStatusDialog(report),
                    onDelete: () => _deleteReport(report),
                  )
                : null,
          ),

          Stack(
            children: [
              if (hasImage)
                _buildMedia(report.imageUrl!)
              else
                AspectRatio(
                  aspectRatio: 16 / 10,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          primaryColor.withOpacity(0.12),
                          primaryColor.withOpacity(0.04),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.pets, size: 38, color: primaryColor),
                        SizedBox(height: 6),
                        Text(
                          'Reporte sem foto',
                          style: TextStyle(
                            color: primaryColor,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              Positioned(
                left: 12,
                bottom: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: typeColor,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    report.type.label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 11.5,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),
            ],
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  report.title,
                  style: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                    color: _textDark,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  report.description,
                  style: const TextStyle(
                    fontSize: 13.5,
                    height: 1.4,
                    color: _textDark,
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 16),
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFAF6F2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.location_on_rounded,
                    size: 18,
                    color: primaryColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FutureBuilder<String>(
                      future: report.fetchAddress(),
                      builder: (context, snapshot) {
                        return Text(
                          snapshot.data ?? 'Buscando endereço...',
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: Color(0xFF6B6B6B),
                            height: 1.25,
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
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: primaryColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.map_outlined,
                            size: 14,
                            color: Colors.white,
                          ),
                          SizedBox(width: 5),
                          Text(
                            'Ver no mapa',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  //palette of colors for the different types of reports
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
