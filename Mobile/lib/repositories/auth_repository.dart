import 'package:dio/dio.dart';
import '../core/network/api_client.dart';
import '../models/auth_response.dart';
import '../models/user_model.dart';

class AuthRepository {
  Future<AuthResponse> login(String correo, String password) async {
    try {
      final response = await apiClient.post('/auth/login', data: {
        'correo': correo,
        'password': password,
      });
      return AuthResponse.fromJson(response.data);
    } catch (e) {
      if (e is DioException) {
        throw Exception(e.response?.data['detail'] ?? 'Error de conexión');
      }
      throw Exception('Error inesperado');
    }
  }

  Future<UserModel> registerClient({
    required String nombre,
    required String apellido,
    required String correo,
    required String password,
    required String telefono,
    required String cedula,
  }) async {
    try {
      final response = await apiClient.post('/auth/register', data: {
        'nombre': nombre,
        'apellido': apellido,
        'correo': correo,
        'password': password,
        'telefono': telefono,
        'cedula': cedula,
      });
      return UserModel.fromJson(response.data);
    } catch (e) {
      if (e is DioException) {
        final data = e.response?.data;
        if (data is Map<String, dynamic>) {
          final detail = data['detail'];
          throw Exception(detail != null ? detail.toString() : 'Error al registrar');
        }
        throw Exception('Error interno del servidor');
      }
      throw Exception('Error inesperado');
    }
  }

  Future<bool> changePassword(String oldPassword, String newPassword) async {
    try {
      await apiClient.post('/auth/change-password', data: {
        'old_password': oldPassword,
        'new_password': newPassword,
      });
      return true;
    } catch (e) {
      if (e is DioException) {
        throw Exception(e.response?.data['detail'] ?? 'Error al cambiar contraseña');
      }
      throw Exception('Error inesperado');
    }
  }

  Future<AuthResponse> updateProfile({
    required String nombre,
    required String apellido,
    required String telefono,
    required String cedula,
  }) async {
    try {
      final response = await apiClient.put('/auth/profile', data: {
        'nombre': nombre,
        'apellido': apellido,
        'telefono': telefono,
        'cedula': cedula,
      });
      return AuthResponse.fromJson(response.data);
    } catch (e) {
      if (e is DioException) {
        throw Exception(e.response?.data['detail'] ?? 'Error al actualizar perfil');
      }
      throw Exception('Error inesperado');
    }
  }
}
