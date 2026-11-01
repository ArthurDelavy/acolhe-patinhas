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
  int? _currentUserId;
  bool _isAdmin = false;
  bool _isLoadingAvatar = true;

  List<FeedItem> _feedItems = [];
  bool _isLoadingFeed = true;
  String? _errorMessage;

  int _currentPage = 0;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  final ScrollController _scrollController = ScrollController();

  final _descriptionController = TextEditingController();
  XFile? _selectedImage;
  bool _isExpanded = false;
  bool _isPublishing = false;

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

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      if (!_isLoadingMore && _hasMore && !_isLoadingFeed) {
        _loadMoreItems();
      }
    }
  }

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
      final results = await Future.wait([
        _reportService.listAll().catchError((_) => <AnimalReport>[]),
        _postService
            .listAll(page: 0, size: 20)
            .catchError((_) => <SocialPost>[]),
      ]);

      final reports = results[0] as List<AnimalReport>;
      final posts = results[1] as List<SocialPost>;

      if (posts.length < 20) {
        _hasMore = false;
      }

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

  Future<void> _deletePost(SocialPost post) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir Publicação'),
        content: const Text(
          'Tem certeza de que deseja remover esta publicação?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Excluir', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
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

  Future<void> _deleteReport(AnimalReport report) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir Reporte'),
        content: const Text(
          'Tem certeza de que deseja remover este reporte de animal?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Excluir', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
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

  void _showUpdateStatusDialog(AnimalReport report) {
    const Color primaryOrange = Color(0xFFE27B1D);

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
              child: const Text('Voltar'),
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
                backgroundColor: primaryOrange,
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

  void _openProfile() {
    Navigator.pushNamed(
      context,
      '/profile',
    ).then((_) => _loadUserAvatarAndInfo());
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
        onRefresh: () => _loadFeed(isSilent: false),
        color: primaryColor,
        child: Column(
          children: [
            _buildCreatePostCard(),
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
                onPressed: () => Navigator.pushNamed(
                  context,
                  '/report',
                ).then((_) => _loadFeed(isSilent: true)),
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
                onPressed: () => _loadFeed(isSilent: false),
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
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
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

  Widget _buildSocialPostCard(SocialPost post) {
    final bool canEditOrDelete =
        _isAdmin || (_currentUserId != null && _currentUserId == post.userId);

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
            trailing: canEditOrDelete
                ? PopupMenuButton<String>(
                    icon: const Icon(
                      Icons.more_vert,
                      size: 18,
                      color: Colors.grey,
                    ),
                    onSelected: (value) {
                      if (value == 'edit') {
                        _showEditPostModal(post);
                      } else if (value == 'delete') {
                        _deletePost(post);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 16, color: primaryColor),
                            SizedBox(width: 8),
                            Text('Editar', style: TextStyle(fontSize: 12)),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 16, color: Colors.red),
                            SizedBox(width: 8),
                            Text(
                              'Excluir',
                              style: TextStyle(color: Colors.red, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                : null,
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

  Widget _buildReportCard(AnimalReport report) {
    // Converte ambos para String para evitar qualquer incompatibilidade de int vs double/String[cite: 6]
    final bool isOwner =
        _currentUserId != null &&
        report.userId != null &&
        _currentUserId.toString() == report.userId.toString();

    final bool canEditOrDelete = _isAdmin || isOwner;
    final String? avatarUrl = report.userPhotoUrl;

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
            leading: CircleAvatar(
              radius: 16,
              backgroundColor: primaryColor.withOpacity(0.1),
              child:
                  (avatarUrl != null &&
                      avatarUrl.trim().isNotEmpty &&
                      avatarUrl != 'null')
                  ? ClipOval(
                      child: Image.network(
                        avatarUrl,
                        width: 32,
                        height: 32,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(
                              Icons.person,
                              size: 18,
                              color: primaryColor,
                            ),
                      ),
                    )
                  : const Icon(Icons.person, size: 18, color: primaryColor),
            ),
            title: Text(
              report.userName ?? 'Usuário Anônimo',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            subtitle: Text(
              report.createdAt != null
                  ? '${report.createdAt!.day.toString().padLeft(2, '0')}/${report.createdAt!.month.toString().padLeft(2, '0')}/${report.createdAt!.year}'
                  : 'Recente',
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: _getTypeColor(report.type).withOpacity(0.1),
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

                // Exibe os 3 pontinhos para o Admin OU para o criador do post[cite: 6]
                if (canEditOrDelete)
                  PopupMenuButton<String>(
                    icon: const Icon(
                      Icons.more_vert,
                      size: 20,
                      color: Colors.grey,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onSelected: (value) {
                      if (value == 'edit') {
                        _showUpdateStatusDialog(report);
                      } else if (value == 'delete') {
                        _deleteReport(report);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 16, color: primaryColor),
                            SizedBox(width: 8),
                            Text(
                              'Alterar Status',
                              style: TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 16, color: Colors.red),
                            SizedBox(width: 8),
                            Text(
                              'Excluir',
                              style: TextStyle(color: Colors.red, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),

          if (report.imageUrl != null && report.imageUrl!.isNotEmpty)
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxHeight: 320),
              color: primaryColor.withOpacity(0.08),
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
              color: Colors.orange.withOpacity(0.08),
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
