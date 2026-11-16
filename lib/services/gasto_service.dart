import '../dao/gasto_dao.dart';
import '../models/gasto_model.dart';

class GastoService {
  static const categorias = ['Mercadería', 'Alquiler', 'Servicios', 'Otros'];

  final _dao = GastoDao();

  Future<List<Gasto>> listar() => _dao.listar();

  Future<void> eliminar(int id) => _dao.eliminar(id);

  Future<void> guardar(Gasto gasto) async {
    if (gasto.descripcion.trim().isEmpty) {
      throw Exception('La descripción es obligatoria');
    }
    if (gasto.monto <= 0) {
      throw Exception('El monto tiene que ser mayor a 0');
    }
    final limpio = Gasto(
      id: gasto.id,
      descripcion: gasto.descripcion.trim(),
      monto: gasto.monto,
      fecha: gasto.fecha,
      categoria: gasto.categoria,
    );
    if (limpio.id == null) {
      await _dao.insertar(limpio);
    } else {
      await _dao.actualizar(limpio);
    }
  }
}
