import 'package:flutter/material.dart';
import 'database/app_database.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Abre la base (la crea la primera vez) y cuenta las categorías cargadas
  final db = await AppDatabase.instance.database;
  final categorias = await db.query('categorias');

  runApp(MaterialApp(
    home: Scaffold(
      appBar: AppBar(title: const Text('Musa Store')),
      body: Center(child: Text('Categorías: ${categorias.length}')),
    ),
  ));
}