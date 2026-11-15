import 'package:flutter/material.dart';
import 'database/app_database.dart';
import 'screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Abre la base de datos (la crea la primera vez) antes de mostrar la app
  await AppDatabase.instance.database;
  runApp(const MusaStoreApp());
}

class MusaStoreApp extends StatelessWidget {
  const MusaStoreApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Musa Store',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF8A3D1F)),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  } 
}
