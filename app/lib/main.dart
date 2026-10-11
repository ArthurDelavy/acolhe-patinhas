import 'package:acolhe_patinhas/features/auth/auth_screen.dart';
import 'package:flutter/material.dart';
import 'package:acolhe_patinhas/features/home/feed.dart';
import 'package:acolhe_patinhas/features/register/register_pets.dart';
import 'package:acolhe_patinhas/features/listPets/list_pets.dart';
import 'package:acolhe_patinhas/features/about-profile/about_screen.dart';
import 'package:acolhe_patinhas/features/about-profile/profile_screen.dart';


void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Acolhe Patinhas',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const AuthScreen(),
      routes: {
        '/feed': (context) => const FeedScreen(),
        '/registerPets': (context) => const RegisterPetsScreen(),
        '/user_pets': (context) =>
            const ListPetsScreen(isAdminMode: false, navIndex: 1),
        '/admin_pets': (context) =>
            const ListPetsScreen(isAdminMode: true, navIndex: 3),
        '/list_pets': (context) =>
            const ListPetsScreen(isAdminMode: false, navIndex: 1),
        '/about-profile': (context) => const AboutScreen(),
        '/profile': (context) => const ProfileScreen(),
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: .center,
          children: [
            const Text('You have pushed the button this many times:'),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
