import 'package:dio/dio.dart';
import '../core/network/api_client.dart';
import '../models/vehicle_model.dart';

class VehicleRepository {
  Future<List<VehicleModel>> getMyVehicles() async {
    try {
      final response = await apiClient.get('/vehicles/mine');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => VehicleModel.fromJson(json)).toList();
      }
      return [];
    } on DioException catch (e) {
      throw Exception(e.response?.data['detail'] ?? 'Error al obtener los vehiculos');
    } catch (e) {
      throw Exception('Error inesperado al obtener los vehiculos');
    }
  }

  Future<VehicleModel> registerVehicle(Map<String, dynamic> data) async {
    try {
      final response = await apiClient.post('/vehicles/', data: data);
      if (response.statusCode == 201) {
        return VehicleModel.fromJson(response.data);
      }
      throw Exception('Error al registrar el vehiculo');
    } on DioException catch (e) {
      throw Exception(e.response?.data['detail'] ?? 'Error de conexion con el servidor');
    } catch (e) {
      throw Exception('Error inesperado al registrar el vehiculo');
    }
  }

  Future<String> generateInvitation(String placa) async {
    try {
      final response = await apiClient.post('/vehicles/$placa/invitations');
      if (response.statusCode == 200) {
        return response.data['codigo_secreto'];
      }
      throw Exception('Error al generar la invitacion');
    } on DioException catch (e) {
      throw Exception(e.response?.data['detail'] ?? 'Error al conectar con el servidor');
    } catch (e) {
      throw Exception('Error inesperado al generar la invitacion');
    }
  }

  Future<String> redeemInvitation(String codigoSecreto) async {
    try {
      final response = await apiClient.post(
        '/vehicles/invitations/redeem', 
        data: {'codigo_secreto': codigoSecreto}
      );
      if (response.statusCode == 200) {
        return response.data['mensaje'];
      }
      throw Exception('Error al canjear la invitacion');
    } on DioException catch (e) {
      throw Exception(e.response?.data['detail'] ?? 'Error al conectar con el servidor');
    } catch (e) {
      throw Exception('Error inesperado al canjear la invitacion');
    }
  }
}
