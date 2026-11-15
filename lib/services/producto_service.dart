import '../dao/producto_dao.dart';
import '../models/categoria_model.dart';
import '../models/producto_model.dart';

/// Reglas de negocio de los productos. Las pantallas hablan con este servicio,
/// nunca con el DAO.
class ProductoService {
  final _dao = ProductoDao();

  Future<List<Producto>> listar() => _dao.listarActivos();

  Future<List<Categoria>> categorias() => _dao.listarCategorias();

  Future<List<Variante>> variantes(int productoId) =>
      _dao.variantesDe(productoId);

  Future<void> darDeBaja(int id) => _dao.darDeBaja(id);

  Future<void> guardar(Producto producto, List<Variante> variantes) async {
    if (producto.nombre.isEmpty) {
      throw Exception('El nombre es obligatorio');
    }
    if (producto.precio <= 0) {
      throw Exception('El precio debe ser mayor a 0');
    }
    if (variantes.isEmpty) {
      throw Exception('Cargá al menos un talle o color');
    }

    final vistos = <String>{};
    final limpias = <Variante>[];
    for (final v in variantes) {
      final talle = v.talle.isEmpty ? 'Único' : v.talle;
      final clave = '${talle.toLowerCase()}|${v.color.toLowerCase()}';
      if (!vistos.add(clave)) {
        throw Exception('Hay un talle y color repetido: $talle ${v.color}'.trim());
      }
      if (v.stock < 0) {
        throw Exception('El stock no puede ser negativo');
      }
      limpias.add(Variante(id: v.id, talle: talle, color: v.color, stock: v.stock));
    }

    if (producto.id == null) {
      await _dao.insertar(producto, limpias);
    } else {
      await _dao.actualizar(producto, limpias);
    }
  }
}
