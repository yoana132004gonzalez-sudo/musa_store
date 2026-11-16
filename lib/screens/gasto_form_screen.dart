import 'package:flutter/material.dart';
import '../models/gasto_model.dart';
import '../services/gasto_service.dart';
import '../utils/formato.dart';

class GastoFormScreen extends StatefulWidget {
  final Gasto? gasto;

  const GastoFormScreen({super.key, this.gasto});

  @override
  State<GastoFormScreen> createState() => _GastoFormScreenState();
}

class _GastoFormScreenState extends State<GastoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = GastoService();
  late final TextEditingController _descripcionCtrl;
  late final TextEditingController _montoCtrl;
  late DateTime _fecha;
  late String _categoria;
  bool _guardando = false;

  bool get _esEdicion => widget.gasto != null;

  @override
  void initState() {
    super.initState();
    final gasto = widget.gasto;
    _descripcionCtrl = TextEditingController(text: gasto?.descripcion ?? '');
    _montoCtrl = TextEditingController(
      text: gasto == null
          ? ''
          : (gasto.monto == gasto.monto.roundToDouble()
              ? gasto.monto.toStringAsFixed(0)
              : gasto.monto.toString()),
    );
    _fecha = gasto == null
        ? DateTime.now()
        : (DateTime.tryParse(gasto.fecha) ?? DateTime.now());
    _categoria = gasto?.categoria ?? 'Mercadería';
  }

  @override
  void dispose() {
    _descripcionCtrl.dispose();
    _montoCtrl.dispose();
    super.dispose();
  }

  Future<void> _elegirFecha() async {
    final elegida = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (elegida == null) return;
    setState(() => _fecha = elegida);
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _guardando = true);
    try {
      final monto =
          double.tryParse(_montoCtrl.text.trim().replaceAll(',', '.')) ?? 0;
      await _service.guardar(Gasto(
        id: widget.gasto?.id,
        descripcion: _descripcionCtrl.text,
        monto: monto,
        // Se guarda al mediodía de ese día para que entre bien en los resúmenes
        fecha: DateTime(_fecha.year, _fecha.month, _fecha.day, 12)
            .toIso8601String(),
        categoria: _categoria,
      ));
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_esEdicion ? 'Editar gasto' : 'Nuevo gasto'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _descripcionCtrl,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Descripción',
                hintText: 'Ej: Compra de remeras',
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Campo obligatorio' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _montoCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Monto',
                prefixText: '\$ ',
              ),
              validator: (v) {
                final n =
                    double.tryParse((v ?? '').trim().replaceAll(',', '.'));
                if (n == null) return 'Ingresá un número';
                if (n <= 0) return 'Tiene que ser mayor a 0';
                return null;
              },
            ),
            const SizedBox(height: 16),
            Text('Categoría', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final c in GastoService.categorias)
                  ChoiceChip(
                    label: Text(c),
                    selected: _categoria == c,
                    onSelected: (_) => setState(() => _categoria = c),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today),
              title: Text('Fecha: ${fechaCorta(_fecha.toIso8601String())}'),
              trailing: const Icon(Icons.edit),
              onTap: _elegirFecha,
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
