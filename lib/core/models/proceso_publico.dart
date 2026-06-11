class RequisitoDocumento {
  final String nombre;
  final String descripcion;
  final List<String> mimeTypesPermitidos; // extensiones (.pdf, .jpg...); vacío = cualquiera
  final bool obligatorio;

  RequisitoDocumento({
    required this.nombre,
    required this.descripcion,
    required this.mimeTypesPermitidos,
    required this.obligatorio,
  });

  factory RequisitoDocumento.fromJson(Map<String, dynamic> json) => RequisitoDocumento(
        nombre: json['nombre'] ?? '',
        descripcion: json['descripcion'] ?? '',
        mimeTypesPermitidos:
            (json['mimeTypesPermitidos'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
        obligatorio: json['obligatorio'] ?? false,
      );
}

class ProcesoPublico {
  final String id;
  final String nombre;
  final String descripcion;
  final List<RequisitoDocumento> documentosRequeridos;

  ProcesoPublico({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.documentosRequeridos,
  });

  factory ProcesoPublico.fromJson(Map<String, dynamic> json) => ProcesoPublico(
        id: json['id'] ?? '',
        nombre: json['nombre'] ?? '',
        descripcion: json['descripcion'] ?? '',
        documentosRequeridos: (json['documentosRequeridos'] as List<dynamic>? ?? [])
            .map((e) => RequisitoDocumento.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

/// Mensaje del chat de recepción.
class ChatMensaje {
  final String rol; // 'usuario' | 'agente'
  final String mensaje;
  ChatMensaje(this.rol, this.mensaje);

  Map<String, dynamic> toJson() => {'rol': rol, 'mensaje': mensaje};
}

class OpcionProceso {
  final String id;
  final String nombre;
  OpcionProceso(this.id, this.nombre);
  factory OpcionProceso.fromJson(Map<String, dynamic> j) =>
      OpcionProceso(j['id'] ?? '', j['nombre'] ?? '');
}

/// Respuesta del clasificador IA.
class ClasificarResponse {
  final String respuesta;
  final String? procesoRecomendadoId;
  final bool requiereAclaracion;
  final List<OpcionProceso> opciones;

  ClasificarResponse({
    required this.respuesta,
    this.procesoRecomendadoId,
    required this.requiereAclaracion,
    required this.opciones,
  });

  factory ClasificarResponse.fromJson(Map<String, dynamic> json) => ClasificarResponse(
        respuesta: json['respuesta'] ?? '',
        procesoRecomendadoId: json['proceso_recomendado_id'],
        requiereAclaracion: json['requiere_aclaracion'] ?? false,
        opciones: (json['opciones'] as List<dynamic>? ?? [])
            .map((e) => OpcionProceso.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
