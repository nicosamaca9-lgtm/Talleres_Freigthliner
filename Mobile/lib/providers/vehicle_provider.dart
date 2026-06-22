import 'package:flutter/material.dart';
import '../models/vehicle_model.dart';
import '../repositories/vehicle_repository.dart';

class VehicleProvider extends ChangeNotifier {
  final VehicleRepository _repository = VehicleRepository();
  
  List<VehicleModel> _vehicles = [];
  bool _isLoading = false;
  String? _error;

  List<VehicleModel> get vehicles => _vehicles;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadMyVehicles() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _vehicles = await _repository.getMyVehicles();
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> registerVehicle(Map<String, dynamic> data) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final newVehicle = await _repository.registerVehicle(data);
      _vehicles.add(newVehicle);
      _error = null;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      throw Exception(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String> generateInvitation(String placa) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final code = await _repository.generateInvitation(placa);
      return code;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      throw Exception(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> redeemInvitation(String codigoSecreto) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _repository.redeemInvitation(codigoSecreto);
      // Reload vehicles because a new one was added to the list
      await loadMyVehicles();
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      throw Exception(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
