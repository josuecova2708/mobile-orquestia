import 'package:dio/dio.dart';
import '../api/api_client.dart';
import '../api/api_constants.dart';
import '../models/proceso_publico.dart';

class RecepcionService {
  final _dio = ApiClient().dio;
  // Dio independiente para el servicio IA (otra base URL, sin JWT)
  final _iaDio = Dio(BaseOptions(
    baseUrl: ApiConstants.iaBaseUrl,
    connectTimeout: const Duration(seconds: 20),
    receiveTimeout: const Duration(seconds: 30),
    headers: {'Content-Type': 'application/json'},
  ));

  /// Procesos habilitados para clientes de la empresa.
  Future<List<ProcesoPublico>> procesosPublicos(String empresaId) async {
    final res = await _dio.get(ApiConstants.procesosPublicos, queryParameters: {'empresaId': empresaId});
    return (res.data as List).map((e) => ProcesoPublico.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Envía la conversación al clasificador IA y obtiene la recomendación.
  Future<ClasificarResponse> clasificar(List<ChatMensaje> historial, List<ProcesoPublico> procesos) async {
    final res = await _iaDio.post(ApiConstants.clasificarTramite, data: {
      'historial': historial.map((m) => m.toJson()).toList(),
      'procesos': procesos.map((p) => {'id': p.id, 'nombre': p.nombre, 'descripcion': p.descripcion}).toList(),
    });
    return ClasificarResponse.fromJson(res.data as Map<String, dynamic>);
  }

  /// Inicia el trámite con los documentos de entrada ya subidos.
  Future<void> iniciarTramite(String procesoId, List<String> documentoIds) async {
    await _dio.post(ApiConstants.clienteIniciarTramite, data: {
      'procesoId': procesoId,
      'documentoIds': documentoIds,
      'variables': <String, dynamic>{},
    });
  }
}
