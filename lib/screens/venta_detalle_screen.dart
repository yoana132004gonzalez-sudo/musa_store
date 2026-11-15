import 'package:flutter/material.dart';
import '../models/venta_model.dart';
import '../services/venta_service.dart';
import '../services/whatsapp_service.dart';
import '../utils/formato.dart';

class VentaDetalleScreen extends StatefulWidget {
  final int ventaId;

  const VentaDetalleScreen({super.key, required this.ventaId});

  @override
  State<VentaDetalleScreen> createState() => _VentaDetalleScreenState();
}

class _VentaDetalleScreenState extends State<VentaDetalleScreen> {
  final _service = VentaService();
  VentaResumen? _venta;
  List<DetalleVenta> _items = [];
  List<Pago> _pagos = [];

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final venta = await _service.obtener(widget.ventaId);
    final items = await _service.detalle(widget.ventaId);
    final pagos = await _service.pagos(widget.ventaId);
    if (!mounted) return;
    setState(() {
      _venta = venta;
      _items = items;
      _pagos = pagos;
    });
  }

  void _avisar(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje)),
    );
  }

  Future<void> _registrarPago() async {
    final venta = _venta;
    if (venta == null) return;

    final montoCtrl =
        TextEditingController(text: venta.saldo.round().toString());
    var metodo = 'Efectivo';

    final confirmado = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Registrar pago'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: montoCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Monto',
                  prefixText: '\$ ',
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  for (final m in ['Efectivo', 'Transferencia'])
                    ChoiceChip(
                      label: Text(m),
                      selected: metodo == m,
                      onSelected: (_) => setLocal(() => metodo = m),
                    ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Registrar'),
            ),
          ],
        ),
      ),
    );
    if (confirmado != true) return;

    final monto =
        double.tryParse(montoCtrl.text.trim().replaceAll(',', '.')) ?? 0;
    try {
      await _service.registrarPago(venta, monto, metodo);
      await _cargar();
    } catch (e) {
      if (!mounted) return;
      _avisar(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _avisarDeuda() async {
    final venta = _venta;
    final telefono = venta?.clienteTelefono;
    if (venta == null || telefono == null) return;
    try {
      await abrirWhatsApp(
        telefono,
        'Hola ${venta.clienteNombre ?? ''}! Te recuerdo que tenés un saldo pendiente de ${pesos(venta.saldo)} en Musa Store. ¡Gracias!',
      );
    } catch (e) {
      if (!mounted) return;
      _avisar('No se pudo abrir WhatsApp');
    }
  }

  @override
  Widget build(BuildContext context) {
    final venta = _venta;
    final tema = Theme.of(context);
    if (venta == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Venta')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('Venta #${venta.id}')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(venta.clienteNombre ?? 'Venta de mostrador',
              style: tema.textTheme.titleLarge),
          Text(fechaHora(venta.fecha), style: tema.textTheme.bodySmall),
          const SizedBox(height: 16),
          Text('Productos', style: tema.textTheme.titleMedium),
          for (final item in _items)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(item.descripcion),
              subtitle: Text('${item.cantidad} x ${pesos(item.precioUnitario)}'),
              trailing: Text(pesos(item.subtotal)),
            ),
          const Divider(),
          _fila('Total', pesos(venta.total), tema.textTheme.titleMedium),
          _fila('Pagado', pesos(venta.pagado), tema.textTheme.bodyLarge),
          _fila(
            'Debe',
            pesos(venta.saldo),
            tema.textTheme.titleMedium?.copyWith(
              color: venta.saldo > 0 ? tema.colorScheme.error : null,
            ),
          ),
          const SizedBox(height: 16),
          Text('Pagos', style: tema.textTheme.titleMedium),
          if (_pagos.isEmpty) const Text('Todavía no hay pagos registrados.'),
          for (final p in _pagos)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(pesos(p.monto)),
              subtitle: Text('${p.metodo} · ${fechaHora(p.fecha)}'),
            ),
          const SizedBox(height: 16),
          if (venta.saldo > 0)
            FilledButton.icon(
              onPressed: _registrarPago,
              icon: const Icon(Icons.payments),
              label: const Text('Registrar pago'),
            ),
          if (venta.saldo > 0 && venta.clienteTelefono != null) ...[
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _avisarDeuda,
              icon: const Icon(Icons.chat),
              label: const Text('Avisar la deuda por WhatsApp'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _fila(String titulo, String valor, TextStyle? estilo) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(titulo, style: estilo), Text(valor, style: estilo)],
      ),
    );
  }
}
