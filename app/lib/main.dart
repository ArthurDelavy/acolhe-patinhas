import 'package:acolhe_patinhas/features/auth/auth_screen.dart';
import 'package:flutter/material.dart';
import 'package:acolhe_patinhas/features/home/feed.dart';
import 'package:acolhe_patinhas/features/register/register_pets.dart';
import 'package:acolhe_patinhas/features/listPets/list_pets.dart';
import 'package:acolhe_patinhas/features/about-profile/about_screen.dart';
import 'package:acolhe_patinhas/features/about-profile/profile_screen.dart';
import 'package:acolhe_patinhas/features/fosters/foster_screen.dart';
import 'package:acolhe_patinhas/features/reports/reports_screen.dart';
import 'package:acolhe_patinhas/features/auth/splash.screen.dart';
import 'package:flutter/services.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      systemNavigationBarColor: Color(0xFFE27B1D),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

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
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFE27B1D)),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
      routes: {
        '/login': (context) => const AuthScreen(),
        '/feed': (context) => const FeedScreen(),
        '/report': (context) => const ReportScreen(),
        '/registerPets': (context) => const RegisterPetsScreen(),
        '/user_pets': (context) =>
            const ListPetsScreen(isAdminMode: false, navIndex: 2),
        '/admin_pets': (context) =>
            const ListPetsScreen(isAdminMode: true, navIndex: 3),
        '/list_pets': (context) =>
            const ListPetsScreen(isAdminMode: false, navIndex: 2),
        '/about-profile': (context) => const AboutScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/fosters': (context) => const FostersScreen(),
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
