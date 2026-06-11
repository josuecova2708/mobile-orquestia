/// Campo de un formulario dinámico de una actividad (igual que en la web).
/// Tipos: TEXTO | NUMERO | BOOLEANO | OPCIONES | FECHA | ARCHIVO | GRID
class CampoFormulario {
  final String nombre;
  final String tipo;
  final String label;
  final bool requerido;
  final List<String> opciones;
  final List<String> mimeTypesPermitidos;
  final List<String> columnas;
  final int? filas;

  CampoFormulario({
    required this.nombre,
    required this.tipo,
    required this.label,
    required this.requerido,
    this.opciones = const [],
    this.mimeTypesPermitidos = const [],
    this.columnas = const [],
    this.filas,
  });

  factory CampoFormulario.fromJson(Map<String, dynamic> json) => CampoFormulario(
        nombre: json['nombre'] ?? '',
        tipo: json['tipo'] ?? 'TEXTO',
        label: json['label'] ?? json['nombre'] ?? '',
        requerido: json['requerido'] ?? false,
        opciones: (json['opciones'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
        mimeTypesPermitidos:
            (json['mimeTypesPermitidos'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
        columnas: (json['columnas'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
        filas: json['filas'] is num ? (json['filas'] as num).toInt() : null,
      );

  static List<CampoFormulario> listFromJson(dynamic json) =>
      (json as List<dynamic>? ?? []).map((e) => CampoFormulario.fromJson(e as Map<String, dynamic>)).toList();
}
