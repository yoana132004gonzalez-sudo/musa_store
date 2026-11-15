import 'package:flutter/material.dart';
import '../services/cliente_service.dart';
import '../services/producto_service.dart';
import 'clientes_screen.dart';
import 'productos_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _productos = 0;
  int _clientes = 0;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final productos = await ProductoService().listar();
    final clientes = await ClienteService().listar();
    if (!mounted) return;
    setState(() {
      _productos = productos.length;
      _clientes = clientes.length;
    });
  }

  Future<void> _abrir(Widget pantalla) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => pantalla),
    );
    _cargar();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Musa Store')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _Tarjeta(
            icono: Icons.checkroom,
            titulo: 'Productos',
            detalle: '$_productos cargados',
            onTap: () => _abrir(const ProductosScreen()),
          ),
          const SizedBox(height: 12),
          _Tarjeta(
            icono: Icons.people,
            titulo: 'Clientes',
            detalle: '$_clientes cargados',
            onTap: () => _abrir(const ClientesScreen()),
          ),
        ],
      ),
    );
  }
}

class _Tarjeta extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String detalle;
  final VoidCallback onTap;

  const _Tarjeta({
    required this.icono,
    required this.titulo,
    required this.detalle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        leading: Icon(icono, size: 36),
        title: Text(titulo, style: Theme.of(context).textTheme.titleMedium),
        subtitle: Text(detalle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
