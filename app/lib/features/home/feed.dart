import 'package:flutter/material.dart';
import '../../components/navbar.dart'; // Ajuste o caminho de importação da sua NavbarComponent

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Meu Feed')),
      body: const Center(child: Text('Aqui vai ficar o feed!')),
      bottomNavigationBar: const NavbarComponent(currentIndex: 0),
    );
  }
}
