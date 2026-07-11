import 'package:flutter/material.dart';
import '../models/booking_model.dart';
import '../models/service_order_model.dart';
import '../repositories/booking_repository.dart';

class BookingProvider extends ChangeNotifier {
  final BookingRepository _repository = BookingRepository();
  
  List<BookingModel> _myBookings = [];
  List<ServiceOrderModel> _myActiveOrders = [];
  
  bool _isLoading = false;
  String? _error;

  List<BookingModel> get myBookings => _myBookings;
  List<ServiceOrderModel> get myActiveOrders => _myActiveOrders;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadDashboardData(int idUsuario) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final futures = await Future.wait([
        _repository.getBookingsByUser(idUsuario),
        _repository.getActiveOrdersByUser(idUsuario),
      ]);
      
      final allBookings = futures[0] as List<BookingModel>;
      _myBookings = allBookings.where((b) => !b.estadoConfirmacion.contains('CANCELADO')).toList();
      
      final activeOrdersRaw = futures[1] as List<dynamic>;
      _myActiveOrders = activeOrdersRaw
          .map((json) => ServiceOrderModel.fromJson(json))
          .toList();
          
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createBooking({
    required int idUsuario,
    required int idVehiculo,
    required String fechaSolicitud,
    required String fechaCita,
    required String horaCita,
    String? observaciones,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _repository.createBooking(
        idUsuario: idUsuario,
        idVehiculo: idVehiculo,
        fechaSolicitud: fechaSolicitud,
        fechaCita: fechaCita,
        horaCita: horaCita,
        observaciones: observaciones,
      );
      await loadDashboardData(idUsuario);
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateBooking({
    required int idUsuario,
    required int idAgendamiento,
    required String fechaCita,
    required String horaCita,
    String? observaciones,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _repository.updateBooking(
        idAgendamiento: idAgendamiento,
        fechaCita: fechaCita,
        horaCita: horaCita,
        observaciones: observaciones,
      );
      await loadDashboardData(idUsuario);
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> cancelBooking(int idAgendamiento, int idUsuario) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _repository.cancelBooking(idAgendamiento);
      await loadDashboardData(idUsuario);
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
