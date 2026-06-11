class EmpresaResumen {
  final String id;
  final String nombre;

  EmpresaResumen({required this.id, required this.nombre});

  factory EmpresaResumen.fromJson(Map<String, dynamic> json) => EmpresaResumen(
        id: json['id'] ?? '',
        nombre: json['nombre'] ?? '',
      );
}

class AuthResponse {
  final String token;
  final String userId;
  final String email;
  final String nombre;
  final String apellido;
  final String rol;
  final String? empresaId;
  final String? departamentoId;
  final List<EmpresaResumen> empresasAdmin;

  AuthResponse({
    required this.token,
    required this.userId,
    required this.email,
    required this.nombre,
    required this.apellido,
    required this.rol,
    this.empresaId,
    this.departamentoId,
    required this.empresasAdmin,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) => AuthResponse(
        token: json['token'] ?? '',
        userId: json['userId'] ?? '',
        email: json['email'] ?? '',
        nombre: json['nombre'] ?? '',
        apellido: json['apellido'] ?? '',
        rol: json['rol'] ?? 'FUNCIONARIO',
        empresaId: json['empresaId'],
        departamentoId: json['departamentoId'],
        empresasAdmin: (json['empresasAdmin'] as List<dynamic>? ?? [])
            .map((e) => EmpresaResumen.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  String get nombreCompleto => '$nombre $apellido';
  bool get isAdmin => rol == 'ADMIN' || rol == 'DISEÑADOR';
  bool get isFuncionario => rol == 'FUNCIONARIO';
  bool get isCliente => rol == 'CLIENTE';
}
