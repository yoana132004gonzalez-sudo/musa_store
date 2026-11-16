import 'package:flutter/material.dart';
import '../models/gasto_model.dart';
import '../services/gasto_service.dart';
import '../utils/formato.dart';
import 'gasto_form_screen.dart';

class GastosScreen extends StatefulWidget {
  const GastosScreen({super.key});

  @override
  State<GastosScreen> createState() => _GastosScreenState();
}

class _GastosScreenState extends State<GastosScreen> {
  final _service = GastoService();
  List<Gasto> _gastos = [];
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
      _gastos = lista;
      _cargando = false;
    });
  }

  Future<void> _abrirFormulario([Gasto? gasto]) async {
    final huboCambios = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => GastoFormScreen(gasto: gasto)),
    );
    if (huboCambios == true) _cargar();
  }

  Future<void> _eliminar(Gasto gasto) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar gasto'),
        content: Text('¿Querés eliminar "${gasto.descripcion}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmar != true) return;
    await _service.eliminar(gasto.id!);
    _cargar();
  }

  @override
  Widget build(BuildContext context) {
    Widget cuerpo;
    if (_cargando) {
      cuerpo = const Center(child: CircularProgressIndicator());
    } else if (_gastos.isEmpty) {
      cuerpo = const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Todavía no cargaste gastos.\nTocá + para agregar el primero.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    } else {
      cuerpo = ListView.separated(
        itemCount: _gastos.length,
        separatorBuilder: (context, indice) => const Divider(height: 1),
        itemBuilder: (context, indice) {
          final g = _gastos[indice];
          return ListTile(
            title: Text(g.descripcion),
            subtitle: Text('${g.categoria} · ${fechaCorta(g.fecha)}'),
            onTap: () => _abrirFormulario(g),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(pesos(g.monto)),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Eliminar',
                  onPressed: () => _eliminar(g),
                ),
              ],
            ),
          );
        },
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Gastos')),
      body: cuerpo,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _abrirFormulario(),
        tooltip: 'Agregar gasto',
        child: const Icon(Icons.add),
      ),
    );
  }
}
