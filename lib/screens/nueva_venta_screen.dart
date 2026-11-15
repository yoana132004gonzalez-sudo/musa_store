import 'package:flutter/material.dart';
import '../models/cliente_model.dart';
import '../models/venta_model.dart';
import '../services/cliente_service.dart';
import '../services/venta_service.dart';
import '../utils/formato.dart';

class NuevaVentaScreen extends StatefulWidget {
  const NuevaVentaScreen({super.key});

  @override
  State<NuevaVentaScreen> createState() => _NuevaVentaScreenState();
}

class _NuevaVentaScreenState extends State<NuevaVentaScreen> {
  final _service = VentaService();
  final _clienteService = ClienteService();
  final _entregaCtrl = TextEditingController();
  final List<ItemVenta> _items = [];

  Cliente? _cliente;
  String _forma = 'Efectivo'; // Efectivo, Transferencia o Fiado
  bool _guardando = false;

  double get _total => _items.fold(0.0, (suma, item) => suma + item.subtotal);
  bool get _esFiado => _forma == 'Fiado';

  @override
  void dispose() {
    _entregaCtrl.dispose();
    super.dispose();
  }

  void _avisar(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje)),
    );
  }

  Future<void> _agregarProducto() async {
    final disponibles = await _service.variantesConStock();
    if (!mounted) return;
    if (disponibles.isEmpty) {
      _avisar('No hay productos con stock. Cargá productos primero.');
      return;
    }

    final elegido = await showModalBottomSheet<VarianteVendible>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: ListView.separated(
          shrinkWrap: true,
          itemCount: disponibles.length,
          separatorBuilder: (context, indice) => const Divider(height: 1),
          itemBuilder: (context, indice) {
            final v = disponibles[indice];
            return ListTile(
              title: Text(v.producto),
              subtitle: Text(
                '${v.detalle} · ${pesos(v.precio)} · Stock: ${v.stock}',
              ),
              onTap: () => Navigator.pop(ctx, v),
            );
          },
        ),
      ),
    );
    if (elegido == null) return;

    setState(() {
      final existentes = _items
          .where((i) => i.variante.varianteId == elegido.varianteId)
          .toList();
      if (existentes.isEmpty) {
        _items.add(ItemVenta(variante: elegido));
      } else if (existentes.first.cantidad < elegido.stock) {
        existentes.first.cantidad++;
      }
    });
  }

  Future<void> _elegirCliente() async {
    final clientes = await _clienteService.listar();
    if (!mounted) return;
    if (clientes.isEmpty) {
      _avisar('Todavía no cargaste clientes. Cargalos desde Clientes.');
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            if (!_esFiado)
              ListTile(
                leading: const Icon(Icons.storefront),
                title: const Text('Sin cliente (mostrador)'),
                onTap: () {
                  setState(() => _cliente = null);
                  Navigator.pop(ctx);
                },
              ),
            for (final c in clientes)
              ListTile(
                leading: const Icon(Icons.person),
                title: Text(c.nombre),
                subtitle: Text(c.telefono ?? 'Sin teléfono'),
                onTap: () {
                  setState(() => _cliente = c);
                  Navigator.pop(ctx);
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmar() async {
    if (_items.isEmpty) {
      _avisar('Agregá al menos un producto');
      return;
    }
    if (_esFiado && _cliente == null) {
      _avisar('Elegí el cliente para registrar un fiado');
      return;
    }

    final entrega = _esFiado
        ? (double.tryParse(_entregaCtrl.text.trim().replaceAll(',', '.')) ?? 0)
        : _total;
    final metodo = _esFiado ? 'Efectivo' : _forma;

    setState(() => _guardando = true);
    try {
      await _service.registrarVenta(
        cliente: _cliente,
        items: _items,
        esFiado: _esFiado,
        pagoInicial: entrega,
        metodoPago: metodo,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _guardando = false);
      _avisar(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Nueva venta')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Productos', style: tema.textTheme.titleMedium),
          const SizedBox(height: 8),
          if (_items.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('Todavía no agregaste productos.'),
            ),
          for (final item in _items)
            Card(
              key: ObjectKey(item),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.variante.producto,
                        style: tema.textTheme.titleSmall),
                    Text(
                      '${item.variante.detalle} · ${pesos(item.variante.precio)}',
                      style: tema.textTheme.bodySmall,
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          onPressed: item.cantidad > 1
                              ? () => setState(() => item.cantidad--)
                              : null,
                        ),
                        Text('${item.cantidad}'),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          onPressed: item.cantidad < item.variante.stock
                              ? () => setState(() => item.cantidad++)
                              : null,
                        ),
                        const Spacer(),
                        Text(pesos(item.subtotal),
                            style: tema.textTheme.titleSmall),
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          tooltip: 'Quitar',
                          onPressed: () => setState(() => _items.remove(item)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _agregarProducto,
              icon: const Icon(Icons.add),
              label: const Text('Agregar producto'),
            ),
          ),
          const Divider(height: 32),
          Text('Forma de pago', style: tema.textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final forma in ['Efectivo', 'Transferencia', 'Fiado'])
                ChoiceChip(
                  label: Text(forma),
                  selected: _forma == forma,
                  onSelected: (_) => setState(() {
                    _forma = forma;
                    if (forma == 'Fiado' && _cliente == null) {
                      _entregaCtrl.clear();
                    }
                  }),
                ),
            ],
          ),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.person_outline),
            title: Text(_cliente?.nombre ??
                (_esFiado ? 'Elegir cliente (obligatorio)' : 'Cliente (opcional)')),
            trailing: const Icon(Icons.chevron_right),
            onTap: _elegirCliente,
          ),
          if (_esFiado)
            TextField(
              controller: _entregaCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Entrega inicial (opcional)',
                prefixText: '\$ ',
              ),
            ),
          const Divider(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total', style: tema.textTheme.titleLarge),
              Text(pesos(_total), style: tema.textTheme.titleLarge),
            ],
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _guardando ? null : _confirmar,
            icon: const Icon(Icons.check),
            label: const Text('Confirmar venta'),
          ),
        ],
      ),
    );
  }
}
