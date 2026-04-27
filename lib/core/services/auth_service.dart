import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/api_client.dart';
import '../api/api_constants.dart';
import '../models/auth_response.dart';

class AuthService extends ChangeNotifier {
  AuthResponse? _user;
  String? _selectedEmpresaId;
  bool _loading = false;
  String? _error;

  AuthResponse? get user => _user;
  bool get loading => _loading;
  String? get error => _error;
  bool get isLoggedIn => _user != null;

  // ID de empresa activa para el admin
  String? get selectedEmpresaId => _selectedEmpresaId;

  // True si el admin necesita seleccionar empresa antes del dashboard
  bool get needsEmpresaSelection =>
      _user != null &&
      _user!.isAdmin &&
      _selectedEmpresaId == null &&
      _user!.empresasAdmin.isNotEmpty;

  Future<void> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    if (token == null) return;

    final userId = prefs.getString('user_id');
    final email = prefs.getString('user_email');
    final nombre = prefs.getString('user_nombre');
    final apellido = prefs.getString('user_apellido');
    final rol = prefs.getString('user_rol');

    if (userId == null || email == null || nombre == null || rol == null) return;

    // Restaurar lista de empresas del admin
    final empresasStr = prefs.getString('empresas_admin') ?? '[]';
    List<EmpresaResumen> empresasAdmin = [];
    try {
      empresasAdmin = (jsonDecode(empresasStr) as List)
          .map((e) => EmpresaResumen.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {}

    _user = AuthResponse(
      token: token,
      userId: userId,
      email: email,
      nombre: nombre,
      apellido: apellido ?? '',
      rol: rol,
      empresaId: prefs.getString('user_empresa_id'),
      empresasAdmin: empresasAdmin,
    );

    // Restaurar empresa seleccionada explícitamente
    _selectedEmpresaId = prefs.getString('selected_empresa_id');

    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _loading = true;
    _error = null;
    _selectedEmpresaId = null;
    notifyListeners();

    try {
      final response = await ApiClient().dio.post(
        ApiConstants.login,
        data: {'email': email, 'password': password},
      );
      final auth = AuthResponse.fromJson(response.data as Map<String, dynamic>);
      await _saveSession(auth);
      _user = auth;
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = _parseError(e);
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> selectEmpresa(String empresaId) async {
    _selectedEmpresaId = empresaId;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_empresa_id', empresaId);
    notifyListeners();
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    _user = null;
    _selectedEmpresaId = null;
    notifyListeners();
  }

  Future<void> _saveSession(AuthResponse auth) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('jwt_token', auth.token);
    await prefs.setString('user_id', auth.userId);
    await prefs.setString('user_email', auth.email);
    await prefs.setString('user_nombre', auth.nombre);
    await prefs.setString('user_apellido', auth.apellido);
    await prefs.setString('user_rol', auth.rol);

    if (auth.empresaId != null) {
      await prefs.setString('user_empresa_id', auth.empresaId!);
    }

    // Persistir lista de empresas para restaurar después de auto-login
    final empresasJson = jsonEncode(
      auth.empresasAdmin.map((e) => {'id': e.id, 'nombre': e.nombre}).toList(),
    );
    await prefs.setString('empresas_admin', empresasJson);
  }

  String _parseError(Object e) {
    if (e.toString().contains('401') || e.toString().contains('403')) {
      return 'Email o contraseña incorrectos';
    }
    if (e.toString().contains('SocketException') ||
        e.toString().contains('Connection')) {
      return 'Sin conexión a internet';
    }
    return 'Error al iniciar sesión. Intenta de nuevo.';
  }
}
