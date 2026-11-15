import 'package:flutter/material.dart';
import '../models/venta_model.dart';
import '../services/venta_service.dart';
import '../utils/formato.dart';
import 'nueva_venta_screen.dart';
import 'venta_detalle_screen.dart';

class VentasScreen extends StatefulWidget {
  const VentasScreen({super.key});

  @override
  State<VentasScreen> createState() => _VentasScreenState();
}

class _VentasScreenState extends State<VentasScreen> {
  final _service = VentaService();
  List<VentaResumen> _ventas = [];
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
      _ventas = lista;
      _cargando = false;
    });
  }

  Future<void> _nuevaVenta() async {
    final registrada = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const NuevaVentaScreen()),
    );
    if (registrada == true) _cargar();
  }

  Future<void> _abrirDetalle(VentaResumen venta) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => VentaDetalleScreen(ventaId: venta.id)),
    );
    _cargar();
  }

  @override
  Widget build(BuildContext context) {
    final colores = Theme.of(context).colorScheme;
    Widget cuerpo;
    if (_cargando) {
      cuerpo = const Center(child: CircularProgressIndicator());
    } else if (_ventas.isEmpty) {
      cuerpo = const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Todavía no registraste ventas.\nTocá + para cargar la primera.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    } else {
      cuerpo = ListView.separated(
        itemCount: _ventas.length,
        separatorBuilder: (context, indice) => const Divider(height: 1),
        itemBuilder: (context, indice) {
          final v = _ventas[indice];
          final debe = v.saldo > 0;
          return ListTile(
            title: Text(v.clienteNombre ?? 'Venta de mostrador'),
            subtitle: Text(fechaHora(v.fecha)),
            onTap: () => _abrirDetalle(v),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(pesos(v.total),
                    style: Theme.of(context).textTheme.titleSmall),
                Text(
                  debe ? 'Debe ${pesos(v.saldo)}' : 'Pagada',
                  style: TextStyle(
                    fontSize: 12,
                    color: debe ? colores.error : colores.primary,
                  ),
                ),
              ],
            ),
          );
        },
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Ventas')),
      body: cuerpo,
      floatingActionButton: FloatingActionButton(
        onPressed: _nuevaVenta,
        tooltip: 'Nueva venta',
        child: const Icon(Icons.add),
      ),
    );
  }
}
