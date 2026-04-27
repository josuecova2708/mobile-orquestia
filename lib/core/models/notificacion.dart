import 'instancia.dart' show parseBackendDate;

class Notificacion {
  final String id;
  final String userId;
  final String tipo;
  final String mensaje;
  final bool leida;
  final DateTime fecha;

  Notificacion({
    required this.id,
    required this.userId,
    required this.tipo,
    required this.mensaje,
    required this.leida,
    required this.fecha,
  });

  factory Notificacion.fromJson(Map<String, dynamic> json) => Notificacion(
        id: json['id'] ?? '',
        userId: json['userId'] ?? '',
        tipo: json['tipo'] ?? '',
        mensaje: json['mensaje'] ?? '',
        leida: json['leida'] ?? false,
        fecha: parseBackendDate(json['fecha']),
      );

  Notificacion copyWith({bool? leida}) => Notificacion(
        id: id,
        userId: userId,
        tipo: tipo,
        mensaje: mensaje,
        leida: leida ?? this.leida,
        fecha: fecha,
      );
}
