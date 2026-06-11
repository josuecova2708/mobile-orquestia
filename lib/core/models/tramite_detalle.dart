import 'instancia.dart' show parseBackendDate;
import 'campo_formulario.dart';

/// Detalle de un trámite del cliente, con el formulario llenado por cada funcionario.
/// Mapea GET /api/cliente/tramites/{id}/detalle
class TramiteDetalle {
  final String id;
  final String procesoNombre;
  final String estado;
  final DateTime fechaInicio;
  final DateTime? fechaFin;
  final List<TareaDetalle> tareas;

  TramiteDetalle({
    required this.id,
    required this.procesoNombre,
    required this.estado,
    required this.fechaInicio,
    this.fechaFin,
    required this.tareas,
  });

  factory TramiteDetalle.fromJson(Map<String, dynamic> json) => TramiteDetalle(
        id: json['id'] ?? '',
        procesoNombre: json['procesoNombre'] ?? '',
        estado: json['estado'] ?? '',
        fechaInicio: parseBackendDate(json['fechaInicio']),
        fechaFin: json['fechaFin'] != null ? parseBackendDate(json['fechaFin']) : null,
        tareas: (json['tareas'] as List<dynamic>? ?? [])
            .map((e) => TareaDetalle.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class TareaDetalle {
  final String nodoLabel;
  final String estado;
  final String? ejecutadoPor;
  final DateTime? fechaCreacion;
  final DateTime? fechaCompletado;
  final List<CampoFormulario> formularioCampos;
  final Map<String, dynamic> datos;

  TareaDetalle({
    required this.nodoLabel,
    required this.estado,
    this.ejecutadoPor,
    this.fechaCreacion,
    this.fechaCompletado,
    this.formularioCampos = const [],
    this.datos = const {},
  });

  factory TareaDetalle.fromJson(Map<String, dynamic> json) => TareaDetalle(
        nodoLabel: json['nodoLabel'] ?? '',
        estado: json['estado'] ?? '',
        ejecutadoPor: json['ejecutadoPor'],
        fechaCreacion: json['fechaCreacion'] != null ? parseBackendDate(json['fechaCreacion']) : null,
        fechaCompletado: json['fechaCompletado'] != null ? parseBackendDate(json['fechaCompletado']) : null,
        formularioCampos: CampoFormulario.listFromJson(json['formularioCampos']),
        datos: (json['datos'] as Map<String, dynamic>?) ?? {},
      );

  bool get isCompletada => estado == 'COMPLETADA';

  /// Pares {label, valor} de lo llenado, ocultando variables internas (__...).
  List<MapEntry<String, dynamic>> get datosVisibles {
    final labels = {for (final c in formularioCampos) c.nombre: c.label};
    return datos.entries
        .where((e) => !e.key.startsWith('__'))
        .map((e) => MapEntry(labels[e.key] ?? e.key, e.value))
        .toList();
  }
}
