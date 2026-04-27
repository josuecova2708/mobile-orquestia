DateTime parseBackendDate(dynamic value) {
  if (value == null) return DateTime.now();
  if (value is List) {
    return DateTime(
      (value[0] as num).toInt(),
      (value[1] as num).toInt(),
      (value[2] as num).toInt(),
      value.length > 3 ? (value[3] as num).toInt() : 0,
      value.length > 4 ? (value[4] as num).toInt() : 0,
      value.length > 5 ? (value[5] as num).toInt() : 0,
    );
  }
  return DateTime.tryParse(value.toString()) ?? DateTime.now();
}

class InstanciaProceso {
  final String id;
  final String procesoId;
  final String procesoNombre;
  final String empresaId;
  final String creadoPor;
  final String creadoPorNombre;
  final String estado;
  final DateTime fechaInicio;
  final DateTime? fechaFin;

  InstanciaProceso({
    required this.id,
    required this.procesoId,
    required this.procesoNombre,
    required this.empresaId,
    required this.creadoPor,
    required this.creadoPorNombre,
    required this.estado,
    required this.fechaInicio,
    this.fechaFin,
  });

  factory InstanciaProceso.fromJson(Map<String, dynamic> json) => InstanciaProceso(
        id: json['id'] ?? '',
        procesoId: json['procesoId'] ?? '',
        procesoNombre: json['procesoNombre'] ?? '',
        empresaId: json['empresaId'] ?? '',
        creadoPor: json['creadoPor'] ?? '',
        creadoPorNombre: json['creadoPorNombre'] ?? '',
        estado: json['estado'] ?? 'ACTIVA',
        fechaInicio: parseBackendDate(json['fechaInicio']),
        fechaFin: json['fechaFin'] != null ? parseBackendDate(json['fechaFin']) : null,
      );

  bool get isActiva => estado == 'ACTIVA';

  String get displayNombre => procesoNombre.isNotEmpty ? procesoNombre : procesoId;
  String get displayCreadoPor => creadoPorNombre.isNotEmpty ? creadoPorNombre : creadoPor;
}

class InstanciaPublica {
  final String id;
  final String nombreProceso;
  final String estado;
  final DateTime fechaInicio;
  final DateTime? fechaFin;
  final List<TimelineItemPublico> timeline;

  InstanciaPublica({
    required this.id,
    required this.nombreProceso,
    required this.estado,
    required this.fechaInicio,
    this.fechaFin,
    required this.timeline,
  });

  factory InstanciaPublica.fromJson(Map<String, dynamic> json) => InstanciaPublica(
        id: json['id'] ?? '',
        nombreProceso: json['nombreProceso'] ?? '',
        estado: json['estado'] ?? '',
        fechaInicio: parseBackendDate(json['fechaInicio']),
        fechaFin: json['fechaFin'] != null ? parseBackendDate(json['fechaFin']) : null,
        timeline: (json['timeline'] as List<dynamic>? ?? [])
            .map((e) => TimelineItemPublico.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class TimelineItemPublico {
  final String nodoLabel;
  final String estado;
  final DateTime? fechaCompletado;

  TimelineItemPublico({
    required this.nodoLabel,
    required this.estado,
    this.fechaCompletado,
  });

  factory TimelineItemPublico.fromJson(Map<String, dynamic> json) => TimelineItemPublico(
        nodoLabel: json['nodoLabel'] ?? '',
        estado: json['estado'] ?? '',
        fechaCompletado: json['fechaCompletado'] != null
            ? parseBackendDate(json['fechaCompletado'])
            : null,
      );
}
