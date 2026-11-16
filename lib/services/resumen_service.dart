import '../dao/resumen_dao.dart';
import '../models/resumen_model.dart';

enum Periodo { hoy, mes, todo }

class ResumenService {
  final _dao = ResumenDao();

  Future<Resumen> calcular(Periodo periodo) {
    final ahora = DateTime.now();
    String desde;
    String hasta;
    switch (periodo) {
      case Periodo.hoy:
        desde = DateTime(ahora.year, ahora.month, ahora.day).toIso8601String();
        hasta =
            DateTime(ahora.year, ahora.month, ahora.day + 1).toIso8601String();
        break;
      case Periodo.mes:
        desde = DateTime(ahora.year, ahora.month).toIso8601String();
        hasta = DateTime(ahora.year, ahora.month + 1).toIso8601String();
        break;
      case Periodo.todo:
        desde = '0000';
        hasta = '9999';
        break;
    }
    return _dao.calcular(desde, hasta);
  }
}
