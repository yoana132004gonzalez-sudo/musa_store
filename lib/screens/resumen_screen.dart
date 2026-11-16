import 'package:flutter/material.dart';
import '../models/resumen_model.dart';
import '../services/resumen_service.dart';
import '../services/venta_service.dart';
import '../utils/formato.dart';

class ResumenScreen extends StatefulWidget {
  const ResumenScreen({super.key});

  @override
  State<ResumenScreen> createState() => _ResumenScreenState();
}

class _ResumenScreenState extends State<ResumenScreen> {
  final _service = ResumenService();
  Periodo _periodo = Periodo.mes;
  Resumen? _resumen;
  double _deuda = 0;

  static const _nombres = {
    Periodo.hoy: 'Hoy',
    Periodo.mes: 'Este mes',
    Periodo.todo: 'Todo',
  };

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final resumen = await _service.calcular(_periodo);
    final ventas = await VentaService().listar();
    final deuda = ventas.fold(0.0, (suma, v) => suma + v.saldo);
    if (!mounted) return;
    setState(() {
      _resumen = resumen;
      _deuda = deuda;
    });
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final resumen = _resumen;

    return Scaffold(
      appBar: AppBar(title: const Text('Resumen')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Wrap(
            spacing: 8,
            children: [
              for (final p in Periodo.values)
                ChoiceChip(
                  label: Text(_nombres[p] ?? ''),
                  selected: _periodo == p,
                  onSelected: (_) {
                    setState(() => _periodo = p);
                    _cargar();
                  },
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (resumen == null)
            const Center(child: CircularProgressIndicator())
          else ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _fila('Ventas', pesos(resumen.ventas), tema),
                    _fila('Costo de lo vendido', pesos(resumen.costo), tema),
                    const Divider(),
                    _fila('Ganancia estimada', pesos(resumen.ganancia), tema,
                        destacado: true),
                    _fila('Gastos', pesos(resumen.gastos), tema),
                    const Divider(),
                    _fila('Resultado', pesos(resumen.resultado), tema,
                        destacado: true),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _fila('Plata cobrada', pesos(resumen.cobrado), tema),
                    _fila('Menos gastos', pesos(resumen.gastos), tema),
                    const Divider(),
                    _fila('Plata disponible', pesos(resumen.disponible), tema,
                        destacado: true),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _fila('Fiados pendientes (total)', pesos(_deuda), tema,
                    destacado: true),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _fila(String titulo, String valor, ThemeData tema,
      {bool destacado = false}) {
    final estilo = destacado
        ? tema.textTheme.titleMedium
        : tema.textTheme.bodyLarge;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(titulo, style: estilo)),
          Text(valor, style: estilo),
        ],
      ),
    );
  }
}
