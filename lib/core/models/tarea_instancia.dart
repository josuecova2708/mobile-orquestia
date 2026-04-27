import 'instancia.dart' show parseBackendDate;

class TareaInstancia {
  final String id;
  final String instanciaId;
  final String nodoLabel;
  final String departamentoId;
  final String? asignadoA;
  final String estado;
  final DateTime fechaCreacion;
  final DateTime? fechaCompletado;

  TareaInstancia({
    required this.id,
    required this.instanciaId,
    required this.nodoLabel,
    required this.departamentoId,
    this.asignadoA,
    required this.estado,
    required this.fechaCreacion,
    this.fechaCompletado,
  });

  factory TareaInstancia.fromJson(Map<String, dynamic> json) => TareaInstancia(
        id: json['id'] ?? '',
        instanciaId: json['instanciaId'] ?? '',
        nodoLabel: json['nodoLabel'] ?? '',
        departamentoId: json['departamentoId'] ?? '',
        asignadoA: json['asignadoA'],
        estado: json['estado'] ?? 'PENDIENTE',
        fechaCreacion: parseBackendDate(json['fechaCreacion']),
        fechaCompletado: json['fechaCompletado'] != null
            ? parseBackendDate(json['fechaCompletado'])
            : null,
      );

  bool get isPendiente => estado == 'PENDIENTE';
  bool get isEnProgreso => estado == 'EN_PROGRESO';
}
