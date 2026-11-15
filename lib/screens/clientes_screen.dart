import 'package:flutter/material.dart';
import '../models/cliente_model.dart';
import '../services/cliente_service.dart';
import '../services/whatsapp_service.dart';
import 'cliente_form_screen.dart';

class ClientesScreen extends StatefulWidget {
  const ClientesScreen({super.key});

  @override
  State<ClientesScreen> createState() => _ClientesScreenState();
}

class _ClientesScreenState extends State<ClientesScreen> {
  final _service = ClienteService();
  List<Cliente> _clientes = [];
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
      _clientes = lista;
      _cargando = false;
    });
  }

  Future<void> _abrirFormulario([Cliente? cliente]) async {
    final huboCambios = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ClienteFormScreen(cliente: cliente),
      ),
    );
    if (huboCambios == true) _cargar();
  }

  Future<void> _darDeBaja(Cliente cliente) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Dar de baja'),
        content: Text('¿Querés dar de baja a "${cliente.nombre}"?'),
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
    await _service.darDeBaja(cliente.id!);
    _cargar();
  }

  Future<void> _escribirPorWhatsApp(Cliente cliente) async {
    final telefono = cliente.telefono;
    if (telefono == null) return;
    try {
      await abrirWhatsApp(
        telefono,
        'Hola ${cliente.nombre}! Te escribo de Musa Store.',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir WhatsApp')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget cuerpo;
    if (_cargando) {
      cuerpo = const Center(child: CircularProgressIndicator());
    } else if (_clientes.isEmpty) {
      cuerpo = const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Todavía no cargaste clientes.\nTocá + para agregar el primero.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    } else {
      cuerpo = ListView.separated(
        itemCount: _clientes.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, indice) {
          final c = _clientes[indice];
          return ListTile(
            title: Text(c.nombre),
            subtitle: Text(c.telefono ?? 'Sin teléfono'),
            onTap: () => _abrirFormulario(c),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.chat),
                  tooltip: 'Escribir por WhatsApp',
                  onPressed:
                      c.telefono == null ? null : () => _escribirPorWhatsApp(c),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Dar de baja',
                  onPressed: () => _darDeBaja(c),
                ),
              ],
            ),
          );
        },
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Clientes')),
      body: cuerpo,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _abrirFormulario(),
        tooltip: 'Agregar cliente',
        child: const Icon(Icons.add),
      ),
    );
  }
}
