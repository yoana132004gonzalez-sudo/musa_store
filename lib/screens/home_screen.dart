import 'package:flutter/material.dart';
import '../services/cliente_service.dart';
import '../services/gasto_service.dart';
import '../services/producto_service.dart';
import '../services/venta_service.dart';
import '../utils/formato.dart';
import 'clientes_screen.dart';
import 'gastos_screen.dart';
import 'productos_screen.dart';
import 'resumen_screen.dart';
import 'ventas_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _productos = 0;
  int _clientes = 0;
  int _ventas = 0;
  int _gastos = 0;
  double _deuda = 0;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final productos = await ProductoService().listar();
    final clientes = await ClienteService().listar();
    final ventas = await VentaService().listar();
    final gastos = await GastoService().listar();
    final deuda = ventas.fold(0.0, (suma, v) => suma + v.saldo);
    if (!mounted) return;
    setState(() {
      _productos = productos.length;
      _clientes = clientes.length;
      _ventas = ventas.length;
      _gastos = gastos.length;
      _deuda = deuda;
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
            icono: Icons.point_of_sale,
            titulo: 'Ventas',
            detalle: '$_ventas registradas · Fiados pendientes: ${pesos(_deuda)}',
            onTap: () => _abrir(const VentasScreen()),
          ),
          const SizedBox(height: 12),
          _Tarjeta(
            icono: Icons.bar_chart,
            titulo: 'Resumen',
            detalle: 'Ventas, gastos y ganancia',
            onTap: () => _abrir(const ResumenScreen()),
          ),
          const SizedBox(height: 12),
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
          const SizedBox(height: 12),
          _Tarjeta(
            icono: Icons.receipt_long,
            titulo: 'Gastos',
            detalle: '$_gastos registrados',
            onTap: () => _abrir(const GastosScreen()),
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
