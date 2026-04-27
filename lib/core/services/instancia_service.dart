import '../api/api_client.dart';
import '../api/api_constants.dart';
import '../models/instancia.dart';
import '../models/tarea_instancia.dart';

class InstanciaService {
  final _dio = ApiClient().dio;
  final _publicDio = ApiClient().publicDio;

  Future<List<InstanciaProceso>> listarInstancias(String empresaId, {String? estado}) async {
    final params = <String, String>{'empresaId': empresaId};
    if (estado != null) params['estado'] = estado;
    final res = await _dio.get(ApiConstants.instancias, queryParameters: params);
    return (res.data as List).map((e) => InstanciaProceso.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<TareaInstancia>> obtenerTareas(String instanciaId) async {
    final res = await _dio.get(ApiConstants.tareasPorInstancia(instanciaId));
    return (res.data as List).map((e) => TareaInstancia.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> cancelarInstancia(String id) async {
    await _dio.delete(ApiConstants.instanciaById(id));
  }

  Future<List<InstanciaProceso>> miHistorial() async {
    final res = await _dio.get(ApiConstants.misInstancias);
    return (res.data as List).map((e) => InstanciaProceso.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<InstanciaPublica> trackPublico(String id) async {
    final res = await _publicDio.get(ApiConstants.publicInstancia(id));
    return InstanciaPublica.fromJson(res.data as Map<String, dynamic>);
  }
}
