import 'dart:convert';
import 'dart:async';

import 'package:flutter/material.dart';
import '../repositories/auth_repository.dart';
import '../core/storage/secure_storage.dart';
import '../models/user_role.dart';
import '../services/push_notification_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepository _repository = AuthRepository();
  final PushNotificationService _pushNotificationService;
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _errorMessage;
  String? _role;
  String? _token;
  int? _userId;
  String? _userName;
  String? _userLastName;
  String? _correo;
  String? _telefono;
  String? _cedula;

  AuthProvider({PushNotificationService? pushService})
    : _pushNotificationService = pushService ?? pushNotificationService {
    _loadSession();
  }

  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  String? get errorMessage => _errorMessage;
  String? get role => _role;
  int? get userId => _userId;
  String? get userName => _userName;
  String? get userLastName => _userLastName;
  String? get correo => _correo;
  String? get telefono => _telefono;
  String? get cedula => _cedula;
  bool get isAuthenticated => _token != null;
  UserRole get userRole => UserRole.fromBackendValue(_role);
  bool get isClient => userRole == UserRole.client;
  bool get isAdmin => userRole == UserRole.admin;
  bool get isMechanic => userRole == UserRole.mechanic;
  bool get isSecretary => userRole == UserRole.secretary;
  String get initials {
    if (_userName != null &&
        _userLastName != null &&
        _userName!.isNotEmpty &&
        _userLastName!.isNotEmpty) {
      return '${_userName![0].toUpperCase()}${_userLastName![0].toUpperCase()}';
    }
    return 'CM';
  }

  Future<void> _loadSession() async {
    _token = await SecureStorage.getToken();
    if (_token != null) {
      _role = _extractRoleFromToken(_token!);
      _userId = _extractUserIdFromToken(_token!);
      _userName = _extractFieldFromToken(_token!, 'name')?.toString();
      _userLastName = _extractFieldFromToken(_token!, 'last_name')?.toString();
      _correo = _extractFieldFromToken(_token!, 'correo')?.toString();
      _telefono = _extractFieldFromToken(_token!, 'telefono')?.toString();
      _cedula = _extractFieldFromToken(_token!, 'cedula')?.toString();
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
      _role = _extractRoleFromToken(_token!);
      _userId = _extractUserIdFromToken(_token!);
      _userName = _extractFieldFromToken(_token!, 'name')?.toString();
      _userLastName = _extractFieldFromToken(_token!, 'last_name')?.toString();
      _correo = _extractFieldFromToken(_token!, 'correo')?.toString();
      _telefono = _extractFieldFromToken(_token!, 'telefono')?.toString();
      _cedula = _extractFieldFromToken(_token!, 'cedula')?.toString();
      unawaited(_pushNotificationService.syncTokenAfterLogin());
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

  Future<bool> updateProfile({
    required String nombre,
    required String apellido,
    required String telefono,
    required String cedula,
  }) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      final authResponse = await _repository.updateProfile(
        nombre: nombre,
        apellido: apellido,
        telefono: telefono,
        cedula: cedula,
      );
      
      await SecureStorage.saveToken(authResponse.accessToken);
      _token = authResponse.accessToken;
      
      _userName = _extractFieldFromToken(_token!, 'name')?.toString();
      _userLastName = _extractFieldFromToken(_token!, 'last_name')?.toString();
      _correo = _extractFieldFromToken(_token!, 'correo')?.toString();
      _telefono = _extractFieldFromToken(_token!, 'telefono')?.toString();
      _cedula = _extractFieldFromToken(_token!, 'cedula')?.toString();
      
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> changePassword(String oldPassword, String newPassword) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      await _repository.changePassword(oldPassword, newPassword);
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> forgotPassword(String correo) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      await _repository.forgotPassword(correo);
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> resetPassword({
    required String correo,
    required String codigo,
    required String nuevaPassword,
  }) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      await _repository.resetPassword(
        correo: correo,
        codigo: codigo,
        nuevaPassword: nuevaPassword,
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
    await _pushNotificationService.removeTokenOnLogout();
    await SecureStorage.deleteToken();
    _token = null;
    _role = null;
    _userId = null;
    _userName = null;
    _userLastName = null;
    _correo = null;
    _telefono = null;
    _cedula = null;
    notifyListeners();
  }

  String? _extractRoleFromToken(String token) {
    return _extractFieldFromToken(token, 'role')?.toString().toLowerCase();
  }

  int? _extractUserIdFromToken(String token) {
    final sub = _extractFieldFromToken(token, 'sub');
    if (sub != null) {
      return int.tryParse(sub.toString());
    }
    return null;
  }

  dynamic _extractFieldFromToken(String token, String field) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;

      final payload = utf8.decode(
        base64Url.decode(base64Url.normalize(parts[1])),
      );
      final data = jsonDecode(payload);

      if (data is Map<String, dynamic>) {
        return data[field];
      }
    } catch (_) {
      return null;
    }
    return null;
  }
}
