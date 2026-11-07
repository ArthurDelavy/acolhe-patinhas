import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/profile_service.dart';
import '../../utils/token_storage.dart';

const Color _primary = Color(0xFFFFA94D);
const Color _secondary = Color(0xFFFF8C42);
const Color _darkOrange = Color(0xFFE0641B);
const Color _background = Color(0xFFF8F9FA);

BoxDecoration _card() => BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(20),
  boxShadow: [
    BoxShadow(
      color: Colors.black.withOpacity(0.04),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ],
);

class ProfileScreen extends StatefulWidget {
  final int? userId;

  const ProfileScreen({super.key, this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late final ProfileService _profileService;
  final ImagePicker _picker = ImagePicker();

  UserProfile? _userProfile;
  UserProfile? _loggedUserProfile;
  bool _isLoading = true;
  bool _isAnonymous = false;

  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _profileService = ProfileService(
      baseUrl: 'https://acolhe-patinhas.duckdns.org/api',
    );

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0.15, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _loadProfiles();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadProfiles() async {
    try {
      final myProfile = await _profileService.getProfile();
      _loggedUserProfile = myProfile;

      if (widget.userId != null) {
        final profile = await _profileService.getUserById(widget.userId!);
        _userProfile = profile;
      } else {
        _userProfile = myProfile;
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
          _isAnonymous = false;
        });
        _controller.forward();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          if (e.toString().contains('anônimos')) {
            _isAnonymous = true;
          } else {
            _snack('Erro ao carregar dados do perfil.');
          }
        });
      }
    }
  }

  Future<void> _pickAndUploadPhoto() async {
    if (widget.userId != null) return;
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 95,
      maxWidth: 1920,
    );
    if (image == null) return;

    _snack('Enviando foto...');
    try {
      final bytes = await image.readAsBytes();
      final updatedProfile = await _profileService.updateProfilePhoto(
        bytes,
        image.name,
      );

      if (mounted) {
        setState(() => _userProfile = updatedProfile);
        _snack('Foto de perfil atualizada com sucesso!');
      }
    } catch (e) {
      _snack('Erro ao modificar a foto.');
    }
  }

  void _editNameDialog() {
    if (widget.userId != null) return;
    final nameController = TextEditingController(
      text: _userProfile?.name ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Nome'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: 'Novo nome'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _secondary),
            onPressed: () async {
              final newName = nameController.text.trim();
              if (newName.isEmpty) return;

              Navigator.pop(context);
              try {
                final updated = await _profileService.updateName(newName);
                if (mounted) {
                  setState(() => _userProfile = updated);
                  _snack('Nome atualizado com sucesso!');
                }
              } catch (e) {
                _snack('Erro ao atualizar o nome.');
              }
            },
            child: const Text('Salvar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _editEmailDialog() {
    if (widget.userId != null) return;
    final emailController = TextEditingController(
      text: _userProfile?.email ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Alterar E-mail'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Um código de verificação será enviado para o novo e-mail informado.',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Novo E-mail'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _secondary),
            onPressed: () async {
              final newEmail = emailController.text.trim();
              if (newEmail.isEmpty || newEmail == _userProfile?.email) return;

              Navigator.pop(context);
              try {
                _snack('Solicitando envio de código...');
                await _profileService.requestEmailChange(newEmail);
                if (mounted) {
                  _showEmailConfirmDialog();
                }
              } catch (e) {
                _snack(e.toString().replaceFirst('Exception: ', ''));
              }
            },
            child: const Text(
              'Enviar Código',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showEmailConfirmDialog() {
    final codeController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Digitar Código'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Insira o código enviado para seu novo e-mail:',
              style: TextStyle(fontSize: 13, color: Colors.black87),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: codeController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Código de Verificação',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _darkOrange),
            onPressed: () async {
              final code = codeController.text.trim();
              if (code.isEmpty) return;

              Navigator.pop(context);
              try {
                await _profileService.confirmEmailChange(code);
                await _loadProfiles();
                _snack('E-mail alterado com sucesso!');
              } catch (e) {
                _snack('Código inválido ou expirado.');
              }
            },
            child: const Text(
              'Confirmar',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showUserSearchModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _UserSearchModal(profileService: _profileService),
    );
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: _darkOrange,
          content: Text(message),
          duration: const Duration(seconds: 3),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    final isOwnProfile = widget.userId == null;

    if (_isLoading) {
      return const Scaffold(
        backgroundColor: _background,
        body: Center(child: CircularProgressIndicator(color: _secondary)),
      );
    }

    if (_isAnonymous) {
      return Scaffold(
        backgroundColor: _background,
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: _primary.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.pets_rounded,
                  size: 72,
                  color: _darkOrange,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Acesso Anônimo',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Para ter perfil, editar seus dados e adotar um animalzinho, basta se cadastrar!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/',
                      (route) => false,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _darkOrange,
                    foregroundColor: Colors.white,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Cadastre-se ou Entre',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_userProfile == null) {
      return const Scaffold(
        backgroundColor: _background,
        body: Center(child: Text('Perfil não encontrado.')),
      );
    }

    final isAdmin = _loggedUserProfile?.role == 'ADMIN';

    return Scaffold(
      backgroundColor: _background,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            _buildHeader(top, isOwnProfile, isAdmin),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SectionTitle('Informações'),
                  _buildInfoCard(isOwnProfile),
                  const SizedBox(height: 32),
                  if (!isOwnProfile && isAdmin && _userProfile!.role != 'ADMIN')
                    _buildAdminVerificationButton(),
                  if (!isOwnProfile && isAdmin) const SizedBox(height: 32),

                  if (isOwnProfile) _buildLogoutButton(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminVerificationButton() {
    final bool isVerified =
        _userProfile!.isVerified || _userProfile!.role == 'VERIFIED';

    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton.icon(
        onPressed: () async {
          try {
            await _profileService.toggleUserVerification(_userProfile!.id);
            _snack('Status de verificação alterado com sucesso!');
            await _loadProfiles();
          } catch (e) {
            _snack('Erro: Não foi possível alterar a verificação.');
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: isVerified
              ? Colors.red.shade100
              : Colors.blue.shade100,
          foregroundColor: isVerified
              ? Colors.red.shade800
              : Colors.blue.shade800,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        icon: Icon(
          isVerified ? Icons.remove_moderator : Icons.verified,
          size: 20,
        ),
        label: Text(
          isVerified ? 'Remover Selo de Verificado' : 'Conceder Verificação',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Widget _buildHeader(double top, bool isOwnProfile, bool isAdmin) {
    final h = 290 + top;
    final name = _userProfile?.name ?? 'Usuário';
    final isVerified = _userProfile?.isVerified ?? false;

    return SizedBox(
      height: h * 0.92,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: h,
            child: ClipPath(
              clipper: HeaderCurveClipper(),
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [_primary, _darkOrange],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: top + 4,
            left: 12,
            child: _roundIcon(
              Icons.arrow_back_ios_new_rounded,
              () => Navigator.maybePop(context),
            ),
          ),

          // Ícone de Pesquisa (Só aparece no PRÓPRIO perfil se for ADMIN)
          if (isOwnProfile && isAdmin)
            Positioned(
              top: top + 4,
              right: 12,
              child: _roundIcon(Icons.search, _showUserSearchModal),
            ),

          Positioned(
            top: top + 64,
            left: 24,
            child: _buildAvatar(isOwnProfile),
          ),
          Positioned(
            top: top + 94,
            left: 152,
            right: 24,
            child: FadeTransition(
              opacity: _fade,
              child: SlideTransition(
                position: _slide,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        if (isVerified || _userProfile?.role == 'ADMIN') ...[
                          const SizedBox(width: 4),
                          Icon(
                            Icons.verified,
                            color: _userProfile?.role == 'ADMIN'
                                ? Colors.black87
                                : Colors.blue.shade200,
                            size: 20,
                          ),
                        ],
                        if (isOwnProfile)
                          IconButton(
                            icon: const Icon(
                              Icons.edit_outlined,
                              color: Colors.white,
                              size: 20,
                            ),
                            onPressed: _editNameDialog,
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '🐾 ${_userProfile?.role ?? "Usuário"}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(bool isOwnProfile) {
    final imageUrl = _userProfile?.profileImageUrl;

    return GestureDetector(
      onTap: isOwnProfile ? _pickAndUploadPhoto : null,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 108,
            height: 108,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(color: Colors.white, width: 4),
            ),
            child: ClipOval(
              child: imageUrl != null && imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      width: 108,
                      height: 108,
                      fit: BoxFit.cover,
                      filterQuality: FilterQuality.high,
                    )
                  : Container(
                      color: _primary.withOpacity(0.18),
                      child: const Icon(
                        Icons.person,
                        size: 64,
                        color: _darkOrange,
                      ),
                    ),
            ),
          ),
          if (isOwnProfile)
            Positioned(
              right: 0,
              bottom: 2,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: _darkOrange,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(
                  Icons.camera_alt,
                  size: 14,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(bool isOwnProfile) {
    final email = _userProfile?.email ?? 'Não informado';

    return Container(
      decoration: _card(),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundColor: _primary.withOpacity(0.15),
              child: const Icon(
                Icons.email_outlined,
                color: _secondary,
                size: 22,
              ),
            ),
            title: const Text(
              'E-mail',
              style: TextStyle(fontSize: 12, color: Colors.black45),
            ),
            subtitle: Text(
              email,
              style: const TextStyle(
                fontSize: 15,
                color: Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
            trailing: isOwnProfile
                ? IconButton(
                    icon: const Icon(
                      Icons.edit_outlined,
                      color: _secondary,
                      size: 20,
                    ),
                    onPressed: _editEmailDialog,
                  )
                : null,
          ),
        ],
      ),
    );
  }

  Widget _roundIcon(IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.white.withOpacity(0.2),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(9),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton.icon(
        onPressed: () async {
          await TokenStorage.clear();

          if (mounted) {
            Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
          }
        },
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.red,
          side: const BorderSide(color: Colors.red, width: 1.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        icon: const Icon(Icons.logout_rounded, size: 20),
        label: const Text(
          'Sair da conta',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }
}

class HeaderCurveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height * 0.78);
    path.quadraticBezierTo(
      size.width * 0.5,
      size.height * 1.15,
      size.width,
      size.height * 0.32,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class _UserSearchModal extends StatefulWidget {
  final ProfileService profileService;

  const _UserSearchModal({required this.profileService});

  @override
  State<_UserSearchModal> createState() => _UserSearchModalState();
}

class _UserSearchModalState extends State<_UserSearchModal> {
  List<UserProfile> _allUsers = [];
  List<UserProfile> _filteredUsers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    try {
      final users = await widget.profileService.listAllUsers();
      if (mounted) {
        setState(() {
          _allUsers = users;
          _filteredUsers = users;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _filterUsers(String query) {
    final lowerQuery = query.toLowerCase();
    setState(() {
      _filteredUsers = _allUsers.where((u) {
        return u.name.toLowerCase().contains(lowerQuery) ||
            u.email.toLowerCase().contains(lowerQuery);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: _background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        children: [
          // Handle do modal
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            height: 4,
            width: 40,
            decoration: BoxDecoration(
              color: Colors.grey.shade400,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Pesquisar Utilizadores',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: TextField(
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search, color: _secondary),
                hintText: 'Nome ou E-mail...',
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: _filterUsers,
            ),
          ),
          const SizedBox(height: 12),

          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: _secondary),
                  )
                : _filteredUsers.isEmpty
                ? const Center(
                    child: Text(
                      'Nenhum utilizador encontrado.',
                      style: TextStyle(color: Colors.black54),
                    ),
                  )
                : ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    itemCount: _filteredUsers.length,
                    itemBuilder: (context, index) {
                      final user = _filteredUsers[index];
                      final isVerified =
                          user.isVerified || user.role == 'VERIFIED';
                      final isAdmin = user.role == 'ADMIN';

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 4,
                        ),
                        leading: CircleAvatar(
                          backgroundColor: _primary.withOpacity(0.2),
                          backgroundImage: user.profileImageUrl != null
                              ? NetworkImage(user.profileImageUrl!)
                              : null,
                          child: user.profileImageUrl == null
                              ? Text(
                                  user.name[0].toUpperCase(),
                                  style: const TextStyle(
                                    color: _darkOrange,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : null,
                        ),
                        title: Row(
                          children: [
                            Flexible(
                              child: Text(
                                user.name,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            if (isVerified || isAdmin) ...[
                              const SizedBox(width: 4),
                              Icon(
                                Icons.verified,
                                size: 16,
                                color: isAdmin ? Colors.orange : Colors.blue,
                              ),
                            ],
                          ],
                        ),
                        subtitle: Text(
                          user.email,
                          style: const TextStyle(fontSize: 12),
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  ProfileScreen(userId: user.id),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
