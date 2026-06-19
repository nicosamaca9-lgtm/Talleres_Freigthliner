import 'package:dio/dio.dart';
import '../core/network/api_client.dart';

class VehicleRepository {
  // Petición para traer todos los vehículos del usuario conectado
  Future<List<dynamic>> fetchVehicles() async {
    try {
      final response = await apiClient.get('/vehicles/');
      if (response.statusCode == 200) {
        return response.data as List<dynamic>;
      }
      return [];
    } on DioException catch (e) {
      print("Error en GET vehicles: ${e.message}");
      rethrow;
    }
  }

  // Petición para registrar un nuevo vehículo
  Future<bool> registerVehicle(Map<String, dynamic> vehicleData) async {
    try {
      final response = await apiClient.post('/vehicles/', data: vehicleData);
      return response.statusCode == 200 || response.statusCode == 201;
    } on DioException catch (e) {
      print("Error en POST vehicle: ${e.response?.data ?? e.message}");
      return false;
    }
  }
}