import 'package:dio/dio.dart';
import '../api/api_client.dart';
import '../api/api_constants.dart';

class IniciarUploadResp {
  final String documentoId;
  final String uploadUrl;
  final String key;
  final String publicUrl;

  IniciarUploadResp({
    required this.documentoId,
    required this.uploadUrl,
    required this.key,
    required this.publicUrl,
  });

  factory IniciarUploadResp.fromJson(Map<String, dynamic> json) => IniciarUploadResp(
        documentoId: json['documentoId'] ?? '',
        uploadUrl: json['uploadUrl'] ?? '',
        key: json['key'] ?? '',
        publicUrl: json['publicUrl'] ?? '',
      );
}

class DocumentoService {
  final _dio = ApiClient().dio;

  /// Registra el documento y obtiene la URL presignada de subida.
  Future<IniciarUploadResp> iniciarUpload({
    required String nombre,
    required String mimeType,
    required int size,
    required String empresaId,
    String? instanciaId,
    String? tareaId,
    String tipo = 'TAREA',
  }) async {
    final res = await _dio.post(ApiConstants.documentoIniciarUpload, data: {
      'nombre': nombre,
      'mimeType': mimeType,
      'size': size,
      'empresaId': empresaId,
      'instanciaId': instanciaId,
      'tareaId': tareaId,
      'tipo': tipo,
    });
    return IniciarUploadResp.fromJson(res.data as Map<String, dynamic>);
  }

  /// Sube los bytes directamente a MinIO usando la URL presignada (sin JWT).
  Future<void> subirBytes(String uploadUrl, List<int> bytes, String mimeType) async {
    final raw = Dio();
    await raw.put(
      uploadUrl,
      data: Stream<List<int>>.fromIterable([bytes]),
      options: Options(
        headers: {
          Headers.contentLengthHeader: bytes.length,
          'Content-Type': mimeType,
        },
      ),
    );
  }

  /// Flujo completo: registra + sube. Devuelve la URL pública del documento.
  Future<String> subirArchivo({
    required String nombre,
    required String mimeType,
    required List<int> bytes,
    required String empresaId,
    String? instanciaId,
    String? tareaId,
  }) async {
    final pre = await iniciarUpload(
      nombre: nombre,
      mimeType: mimeType,
      size: bytes.length,
      empresaId: empresaId,
      instanciaId: instanciaId,
      tareaId: tareaId,
    );
    await subirBytes(pre.uploadUrl, bytes, mimeType);
    return pre.publicUrl;
  }
}
