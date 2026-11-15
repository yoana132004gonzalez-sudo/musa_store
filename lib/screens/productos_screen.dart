import 'package:flutter/material.dart';
import '../models/producto_model.dart';
import '../services/producto_service.dart';
import '../utils/formato.dart';
import 'producto_form_screen.dart';

class ProductosScreen extends StatefulWidget {
  const ProductosScreen({super.key});

  @override
  State<ProductosScreen> createState() => _ProductosScreenState();
}

class _ProductosScreenState extends State<ProductosScreen> {
  final _service = ProductoService();
  List<Producto> _productos = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final lista = await _service.listar();
    if (!mounted) return;
    setState(() {
      _productos = lista;
      _cargando = false;
    });
  }

  Future<void> _abrirFormulario([Producto? producto]) async {
    final huboCambios = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ProductoFormScreen(producto: producto),
      ),
    );
    if (huboCambios == true) _cargar();
  }

  Future<void> _darDeBaja(Producto producto) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Dar de baja'),
        content: Text(
          '¿Querés dar de baja "${producto.nombre}"? Va a quedar en el historial de ventas.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Dar de baja'),
          ),
        ],
      ),
    );
    if (confirmar != true) return;
    await _service.darDeBaja(producto.id!);
    _cargar();
  }

  @override
  Widget build(BuildContext context) {
    Widget cuerpo;
    if (_cargando) {
      cuerpo = const Center(child: CircularProgressIndicator());
    } else if (_productos.isEmpty) {
      cuerpo = const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Todavía no cargaste productos.\nTocá + para agregar el primero.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    } else {
      cuerpo = ListView.separated(
        itemCount: _productos.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, indice) {
          final p = _productos[indice];
          return ListTile(
            title: Text(p.nombre),
            subtitle: Text(
              '${p.categoriaNombre} · ${pesos(p.precio)} · Stock: ${p.stockTotal}',
            ),
            onTap: () => _abrirFormulario(p),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Dar de baja',
              onPressed: () => _darDeBaja(p),
            ),
          );
        },
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Productos')),
      body: cuerpo,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _abrirFormulario(),
        tooltip: 'Agregar producto',
        child: const Icon(Icons.add),
      ),
    );
  }
}
