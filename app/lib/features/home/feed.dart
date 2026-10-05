import 'package:flutter/material.dart';
import '../../components/navbar.dart';
import '../about-profile/profile_screen.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  static const Color primaryColor = Color(0xFFE27B1D);

  void _openProfile() {
    Navigator.pushNamed(context, '/profile');
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
              child: const CircleAvatar(
                radius: 18,
                backgroundColor: Colors.white,
                child: Icon(Icons.person, size: 24, color: primaryColor),
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
