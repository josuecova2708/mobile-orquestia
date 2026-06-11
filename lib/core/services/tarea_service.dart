import '../api/api_client.dart';
import '../api/api_constants.dart';
import '../models/tarea_instancia.dart';

class TareaService {
  final _dio = ApiClient().dio;

  Future<List<TareaInstancia>> misTareas() async {
    final res = await _dio.get(ApiConstants.misTareas);
    return (res.data as List).map((e) => TareaInstancia.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> iniciarTarea(String tareaId) async {
    await _dio.put(ApiConstants.iniciarTarea(tareaId));
  }

  Future<void> completarTarea(String tareaId, Map<String, dynamic> datos, String? comentario) async {
    await _dio.put(
      ApiConstants.completarTarea(tareaId),
      data: {'datos': datos, 'comentario': comentario ?? ''},
    );
  }
}
