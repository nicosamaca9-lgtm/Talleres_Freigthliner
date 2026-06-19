import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

class VehicleProvider extends ChangeNotifier {
  final Dio _dio = Dio(BaseOptions(baseUrl: "http://10.0.2.2:8000"));
  
  Map<String, dynamic>? _vehicleData;
  bool _isLoading = false;

  Map<String, dynamic>? get vehicleData => _vehicleData;
  bool get isLoading => _isLoading;

  Future<void> fetchVehicleData(int userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _dio.get('/vehiculos/usuario/$userId');
      _vehicleData = response.data;
    } catch (e) {
      debugPrint("Error al traer los datos: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}