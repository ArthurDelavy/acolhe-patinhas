import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../features/auth/auth_screen.dart';
import '../../features/home/feed.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final _authService = AuthService(
    baseUrl: 'https://acolhe-patinhas.duckdns.org/api',
  ); // Use sua URL real aqui

  @override
  void initState() {
    super.initState();
    _checkAuthentication();
  }

  Future<void> _checkAuthentication() async {
    await Future.delayed(const Duration(milliseconds: 500));

    final hasSession = await _authService.hasValidSession();

    if (!mounted) return;

    if (hasSession) {
      Navigator.pushReplacementNamed(context, '/feed');
    } else {
      // Usuário não está logado, manda para o Login (AuthScreen).
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AuthScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFE27B1D),
      body: Center(child: CircularProgressIndicator(color: Colors.white)),
    );
  }
}
