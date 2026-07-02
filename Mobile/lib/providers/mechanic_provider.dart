import 'package:flutter/material.dart';
import '../models/service_order_model.dart';
import '../repositories/mechanic_repository.dart';

class MechanicProvider with ChangeNotifier {
  final MechanicRepository _repository = MechanicRepository();

  List<ServiceOrderModel> _assignedOrders = [];
  bool _isLoading = false;
  String? _error;

  List<ServiceOrderModel> get assignedOrders => _assignedOrders;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadAssignedOrders(int mechanicId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _assignedOrders = await _repository.getMyAssignedOrders(mechanicId);
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
