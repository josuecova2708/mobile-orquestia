import '../api/api_client.dart';
import '../api/api_constants.dart';
import '../models/tarea_instancia.dart';

class TareaService {
  final _dio = ApiClient().dio;

  Future<List<TareaInstancia>> misTareas() async {
    final res = await _dio.get(ApiConstants.misTareas);
    return (res.data as List).map((e) => TareaInstancia.fromJson(e as Map<String, dynamic>)).toList();
  }
}
