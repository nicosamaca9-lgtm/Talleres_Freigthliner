import 'package:flutter/material.dart';
import '../models/vehicle_model.dart';
import '../repositories/vehicle_repository.dart';

class VehicleProvider extends ChangeNotifier {
  VehicleProvider({VehicleRepository? repository})
    : _repository = repository ?? VehicleRepository();

  final VehicleRepository _repository;

  List<VehicleModel> _vehicles = [];
  List<dynamic> _activeServiceOrders = [];
  bool _isLoading = false;
  String? _error;

  List<VehicleModel> get vehicles => _vehicles;
  List<dynamic> get activeServiceOrders => _activeServiceOrders;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadMyVehicles(int userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _vehicles = await _repository.getMyVehicles();
      _activeServiceOrders = await _repository.getActiveServiceOrders(userId);
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
      final index = _vehicles.indexWhere(
        (vehicle) =>
            vehicle.idVehiculo == newVehicle.idVehiculo ||
            vehicle.placa == newVehicle.placa,
      );
      if (index == -1) {
        _vehicles.add(newVehicle);
      } else {
        _vehicles[index] = newVehicle;
      }
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

  Future<void> redeemInvitation(String codigoSecreto, int userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _repository.redeemInvitation(codigoSecreto);
      // Reload vehicles because a new one was added to the list
      await loadMyVehicles(userId);
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      throw Exception(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> removeDriver(String placa, int userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _repository.removeDriver(placa);
      await loadMyVehicles(userId);
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      throw Exception(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
