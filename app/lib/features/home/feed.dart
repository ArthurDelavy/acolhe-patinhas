import 'package:flutter/material.dart';
import '../../components/navbar.dart';
import '../../services/profile_service.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  static const Color primaryColor = Color(0xFFE27B1D);
  late final ProfileService _profileService;

  String? _profileImageUrl;
  bool _isLoadingAvatar = true;

  @override
  void initState() {
    super.initState();
    _profileService = ProfileService(baseUrl: 'http://localhost:8080');
    _loadUserAvatar();
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

  void _openProfile() {
    Navigator.pushNamed(context, '/profile').then((_) {
      _loadUserAvatar();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 48,
        title: const Text('Meu Feed', style: TextStyle(fontSize: 16)),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: InkWell(
              onTap: _openProfile,
              customBorder: const CircleBorder(),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: Colors.white,
                child: _isLoadingAvatar
                    ? const SizedBox(
                        width: 14,
                        height: 14,
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
                                width: 36,
                                height: 36,
                                fit: BoxFit.cover,
                                filterQuality: FilterQuality.high,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(
                                      Icons.person,
                                      size: 24,
                                      color: primaryColor,
                                    ),
                              )
                            : const Icon(
                                Icons.person,
                                size: 24,
                                color: primaryColor,
                              ),
                      ),
              ),
            ),
          ),
        ],
      ),
      body: const Center(child: Text('Aqui vai ficar o feed!')),
      bottomNavigationBar: const NavbarComponent(currentIndex: 0),
    );
  }
}
