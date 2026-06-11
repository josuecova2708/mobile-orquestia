import '../api/api_client.dart';
import '../api/api_constants.dart';
import '../models/instancia.dart';
import '../models/tarea_instancia.dart';
import '../models/tramite_detalle.dart';

class ClienteService {
  final _dio = ApiClient().dio;

  /// Trámites iniciados por el cliente autenticado.
  Future<List<InstanciaProceso>> misTramites() async {
    final res = await _dio.get(ApiConstants.clienteMisTramites);
    return (res.data as List).map((e) => InstanciaProceso.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Detalle de un trámite con los formularios llenados por cada funcionario.
  Future<TramiteDetalle> detalle(String instanciaId) async {
    final res = await _dio.get(ApiConstants.clienteTramiteDetalle(instanciaId));
    return TramiteDetalle.fromJson(res.data as Map<String, dynamic>);
  }

  /// Acciones de autoservicio pendientes asignadas al cliente.
  Future<List<TareaInstancia>> misAcciones() async {
    final res = await _dio.get(ApiConstants.clienteMisAcciones);
    return (res.data as List).map((e) => TareaInstancia.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// El cliente completa una de sus acciones; el motor avanza el proceso.
  Future<void> completarAccion(String tareaId, Map<String, dynamic> datos, String? comentario) async {
    await _dio.post(
      ApiConstants.clienteCompletarAccion(tareaId),
      data: {'datos': datos, 'comentario': comentario ?? ''},
    );
  }
}
