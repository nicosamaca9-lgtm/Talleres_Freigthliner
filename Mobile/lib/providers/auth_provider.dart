import 'dart:convert';

import 'package:flutter/material.dart';
import '../repositories/auth_repository.dart';
import '../core/storage/secure_storage.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepository _repository = AuthRepository();
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _errorMessage;
  String? _role;
  String? _token;
  int? _userId;

  AuthProvider() {
    _loadSession();
  }

  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  String? get errorMessage => _errorMessage;
  String? get role => _role;
  int? get userId => _userId;
  bool get isAuthenticated => _token != null;
  bool get isClient => _role == 'client' || _role == 'cliente';

  Future<void> _loadSession() async {
    _token = await SecureStorage.getToken();
    if (_token != null) {
      _role = _extractRoleFromToken(_token!);
      _userId = _extractUserIdFromToken(_token!);
    }
    _isInitialized = true;
    notifyListeners();
  }

  Future<bool> login(String correo, String password) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      final response = await _repository.login(correo, password);
      // Guardar el JWT token
      await SecureStorage.saveToken(response.accessToken);
      _token = response.accessToken;
      _role = _extractRoleFromToken(response.accessToken);
      _userId = _extractUserIdFromToken(response.accessToken);
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> register({
    required String nombre,
    required String apellido,
    required String correo,
    required String password,
    required String telefono,
    required String cedula,
  }) async {
    _setLoading(true);
    try {
      await _repository.registerClient(
        nombre: nombre,
        apellido: apellido,
        correo: correo,
        password: password,
        telefono: telefono,
        cedula: cedula,
      );
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _setLoading(false);
      return false;
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> logout() async {
    await SecureStorage.deleteToken();
    _token = null;
    _role = null;
    notifyListeners();
  }

  String? _extractRoleFromToken(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;

      final payload = utf8.decode(
        base64Url.decode(base64Url.normalize(parts[1])),
      );
      final data = jsonDecode(payload);

      if (data is Map<String, dynamic>) {
        return data['role']?.toString().toLowerCase();
      }
    } catch (_) {
      return null;
    }

    return null;
  }

  int? _extractUserIdFromToken(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;

      final payload = utf8.decode(
        base64Url.decode(base64Url.normalize(parts[1])),
      );
      final data = jsonDecode(payload);

      if (data is Map<String, dynamic>) {
        return int.tryParse(data['sub']?.toString() ?? '');
      }
    } catch (_) {
      return null;
    }
    return null;
  }
}
