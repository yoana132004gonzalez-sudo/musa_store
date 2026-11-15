import 'package:flutter/material.dart';
import '../models/categoria_model.dart';
import '../models/producto_model.dart';
import '../services/producto_service.dart';

/// Una fila del formulario: talle, color y stock de una variante.
class _FilaVariante {
  final int? id;
  final TextEditingController talle;
  final TextEditingController color;
  final TextEditingController stock;

  _FilaVariante({
    this.id,
    String talleInicial = '',
    String colorInicial = '',
    String stockInicial = '',
  })  : talle = TextEditingController(text: talleInicial),
        color = TextEditingController(text: colorInicial),
        stock = TextEditingController(text: stockInicial);

  void dispose() {
    talle.dispose();
    color.dispose();
    stock.dispose();
  }
}

double _leerNumero(String texto) {
  return double.tryParse(texto.trim().replaceAll(',', '.')) ?? 0;
}

String _numeroATexto(double valor) {
  return valor == valor.roundToDouble()
      ? valor.toStringAsFixed(0)
      : valor.toString();
}

class ProductoFormScreen extends StatefulWidget {
  final Producto? producto;

  const ProductoFormScreen({super.key, this.producto});

  @override
  State<ProductoFormScreen> createState() => _ProductoFormScreenState();
}

class _ProductoFormScreenState extends State<ProductoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = ProductoService();
  final _nombreCtrl = TextEditingController();
  final _costoCtrl = TextEditingController();
  final _precioCtrl = TextEditingController();
  final List<_FilaVariante> _filas = [];

  List<Categoria> _categorias = [];
  int? _categoriaId;
  bool _errorCategoria = false;
  bool _guardando = false;

  bool get _esEdicion => widget.producto != null;

  @override
  void initState() {
    super.initState();
    _inicializar();
  }

  Future<void> _inicializar() async {
    final categorias = await _service.categorias();
    final producto = widget.producto;
    final filas = <_FilaVariante>[];

    if (producto != null) {
      _nombreCtrl.text = producto.nombre;
      _costoCtrl.text = _numeroATexto(producto.costo);
      _precioCtrl.text = _numeroATexto(producto.precio);
      final variantes = await _service.variantes(producto.id!);
      for (final v in variantes) {
        filas.add(_FilaVariante(
          id: v.id,
          talleInicial: v.talle,
          colorInicial: v.color,
          stockInicial: v.stock.toString(),
        ));
      }
    }
    if (filas.isEmpty) filas.add(_FilaVariante());

    if (!mounted) return;
    setState(() {
      _categorias = categorias;
      _categoriaId = producto?.categoriaId;
      _filas.addAll(filas);
    });
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _costoCtrl.dispose();
    _precioCtrl.dispose();
    for (final fila in _filas) {
      fila.dispose();
    }
    super.dispose();
  }

  void _agregarFila() {
    setState(() => _filas.add(_FilaVariante()));
  }

  void _quitarFila(_FilaVariante fila) {
    setState(() => _filas.remove(fila));
    // Se liberan los controladores recién después de redibujar la pantalla
    WidgetsBinding.instance.addPostFrameCallback((_) => fila.dispose());
  }

  Future<void> _guardar() async {
    final formularioValido = _formKey.currentState!.validate();
    setState(() => _errorCategoria = _categoriaId == null);
    if (!formularioValido || _categoriaId == null) return;

    setState(() => _guardando = true);
    try {
      final producto = Producto(
        id: widget.producto?.id,
        nombre: _nombreCtrl.text.trim(),
        categoriaId: _categoriaId!,
        costo: _leerNumero(_costoCtrl.text),
        precio: _leerNumero(_precioCtrl.text),
      );
      final variantes = _filas
          .map((f) => Variante(
                id: f.id,
                talle: f.talle.text.trim(),
                color: f.color.text.trim(),
                stock: int.tryParse(f.stock.text.trim()) ?? 0,
              ))
          .toList();

      await _service.guardar(producto, variantes);
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _guardando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  String? _validarDinero(String? valor, {required bool permitirCero}) {
    final numero = double.tryParse((valor ?? '').trim().replaceAll(',', '.'));
    if (numero == null) return 'Ingresá un número';
    if (permitirCero ? numero < 0 : numero <= 0) {
      return permitirCero ? 'No puede ser negativo' : 'Tiene que ser mayor a 0';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_esEdicion ? 'Editar producto' : 'Nuevo producto'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nombreCtrl,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Nombre',
                hintText: 'Ej: Remera lisa',
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Campo obligatorio' : null,
            ),
            const SizedBox(height: 16),
            Text('Categoría', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final c in _categorias)
                  ChoiceChip(
                    label: Text(c.nombre),
                    selected: _categoriaId == c.id,
                    onSelected: (_) => setState(() {
                      _categoriaId = c.id;
                      _errorCategoria = false;
                    }),
                  ),
              ],
            ),
            if (_errorCategoria)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  'Elegí una categoría',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontSize: 12,
                  ),
                ),
              ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _costoCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Costo',
                      prefixText: '\$ ',
                    ),
                    validator: (v) => _validarDinero(v, permitirCero: true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _precioCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Precio de venta',
                      prefixText: '\$ ',
                    ),
                    validator: (v) => _validarDinero(v, permitirCero: false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text('Talles y colores',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              'Cada talle y color tiene su propio stock. En accesorios podés dejar el talle vacío.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            for (final fila in _filas)
              Padding(
                key: ObjectKey(fila),
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: fila.talle,
                        decoration: const InputDecoration(labelText: 'Talle'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 3,
                      child: TextFormField(
                        controller: fila.color,
                        decoration: const InputDecoration(labelText: 'Color'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: fila.stock,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Stock'),
                        validator: (v) {
                          final n = int.tryParse((v ?? '').trim());
                          if (n == null || n < 0) return 'Número';
                          return null;
                        },
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      tooltip: 'Quitar',
                      onPressed:
                          _filas.length > 1 ? () => _quitarFila(fila) : null,
                    ),
                  ],
                ),
              ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _agregarFila,
                icon: const Icon(Icons.add),
                label: const Text('Agregar talle o color'),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _guardando ? null : _guardar,
              icon: const Icon(Icons.save),
              label: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }
}
