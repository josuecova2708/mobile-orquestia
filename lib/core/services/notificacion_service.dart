import '../api/api_client.dart';
import '../api/api_constants.dart';
import '../models/notificacion.dart';

class NotificacionService {
  final _dio = ApiClient().dio;

  Future<List<Notificacion>> listar() async {
    final res = await _dio.get(ApiConstants.notificaciones);
    return (res.data as List).map((e) => Notificacion.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<int> contarNoLeidas() async {
    final res = await _dio.get(ApiConstants.notificacionesNoLeidas);
    return (res.data as num).toInt();
  }

  Future<void> marcarLeida(String id) async {
    await _dio.put(ApiConstants.notificacionLeer(id));
  }

  Future<void> marcarTodasLeidas() async {
    await _dio.put(ApiConstants.notificacionesLeerTodas);
  }
}
