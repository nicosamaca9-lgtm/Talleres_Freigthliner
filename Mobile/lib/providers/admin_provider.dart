import 'package:flutter/material.dart';
import '../repositories/admin_repository.dart';
import '../models/booking_model.dart';
import '../models/service_order_model.dart';
import '../models/technical_report_model.dart';
import '../models/user_model.dart';

class AdminProvider with ChangeNotifier {
  final AdminRepository _repository = AdminRepository();

  bool _isLoading = false;
  String? _error;

  Map<String, dynamic>? _stats;
  List<BookingModel> _allBookings = [];
  List<TechnicalReportModel> _pendingReports = [];
  List<UserModel> _users = [];
  List<ServiceOrderModel> _serviceOrders = [];
  Map<String, dynamic>? _vehicleHistory;
  List<dynamic> _allVehicles = [];

  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, dynamic>? get stats => _stats;
  List<BookingModel> get allBookings => _allBookings;
  List<TechnicalReportModel> get pendingReports => _pendingReports;
  List<UserModel> get users => _users;
  List<ServiceOrderModel> get serviceOrders => _serviceOrders;
  Map<String, dynamic>? get vehicleHistory => _vehicleHistory;
  List<dynamic> get allVehicles => _allVehicles;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? message) {
    _error = message;
    notifyListeners();
  }

  Future<void> fetchStats() async {
    _setLoading(true);
    _setError(null);
    try {
      _stats = await _repository.getStats();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchAllBookings() async {
    _setLoading(true);
    _setError(null);
    try {
      _allBookings = await _repository.getAllBookings();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchPendingReports() async {
    _setLoading(true);
    _setError(null);
    try {
      _pendingReports = await _repository.getPendingReports();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> confirmBooking(int id) async {
    _setLoading(true);
    _setError(null);
    try {
      await _repository.confirmBooking(id);
      final index = _allBookings.indexWhere((b) => b.idAgendamiento == id);
      if (index != -1) {
        final current = _allBookings[index];
        _allBookings[index] = BookingModel(
          idAgendamiento: current.idAgendamiento,
          idUsuario: current.idUsuario,
          idVehiculo: current.idVehiculo,
          fechaSolicitud: current.fechaSolicitud,
          fechaCita: current.fechaCita,
          horaCita: current.horaCita,
          estadoConfirmacion: 'CONFIRMADO',
          observaciones: current.observaciones,
          motivoRechazo: current.motivoRechazo,
          clienteNombre: current.clienteNombre,
          clienteTelefono: current.clienteTelefono,
          clienteCedula: current.clienteCedula,
          placaVehiculo: current.placaVehiculo,
        );
      }
      fetchStats();
    } catch (e) {
      _setError(e.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> rejectBooking(int id, String motivoRechazo) async {
    _setLoading(true);
    _setError(null);
    try {
      await _repository.rejectBooking(id, motivoRechazo);
      final index = _allBookings.indexWhere((b) => b.idAgendamiento == id);
      if (index != -1) {
        final current = _allBookings[index];
        _allBookings[index] = BookingModel(
          idAgendamiento: current.idAgendamiento,
          idUsuario: current.idUsuario,
          idVehiculo: current.idVehiculo,
          fechaSolicitud: current.fechaSolicitud,
          fechaCita: current.fechaCita,
          horaCita: current.horaCita,
          estadoConfirmacion: 'RECHAZADO',
          observaciones: current.observaciones,
          motivoRechazo: motivoRechazo,
          clienteNombre: current.clienteNombre,
          clienteTelefono: current.clienteTelefono,
          clienteCedula: current.clienteCedula,
          placaVehiculo: current.placaVehiculo,
        );
      }
      fetchStats();
    } catch (e) {
      _setError(e.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchUsers() async {
    _setLoading(true);
    _setError(null);
    try {
      _users = await _repository.getAllUsers();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchAllVehicles() async {
    _setLoading(true);
    _setError(null);
    try {
      _allVehicles = await _repository.getAllVehicles();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteUser(int id) async {
    _setLoading(true);
    _setError(null);
    try {
      await _repository.deleteUser(id);
      _users.removeWhere((u) => u.idUsuario == id);
    } catch (e) {
      _setError(e.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchServiceOrders() async {
    _setLoading(true);
    _setError(null);
    try {
      _serviceOrders = await _repository.getAllServiceOrders();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> createServiceOrder(Map<String, dynamic> data) async {
    _setLoading(true);
    _setError(null);
    try {
      await _repository.createServiceOrder(data);
      await fetchServiceOrders();
      await fetchAllBookings(); // Refrescar porque una cita pudo pasar a EN_TALLER
      await fetchStats();
    } catch (e) {
      _setError(e.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> assignMechanic(int idOrden, int idMecanico) async {
    _setLoading(true);
    _setError(null);
    try {
      await _repository.assignMechanic(idOrden, idMecanico);
      await fetchServiceOrders();
    } catch (e) {
      _setError(e.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchVehicleHistory(String placa) async {
    _setLoading(true);
    _setError(null);
    try {
      _vehicleHistory = await _repository.getVehicleHistory(placa);
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> reviewReport(int id, String estado, String? observaciones) async {
    _setLoading(true); _setError(null);
    try { await _repository.reviewReport(id, estado, observaciones); fetchStats(); }
    catch (e) { _setError(e.toString()); rethrow; }
    finally { _setLoading(false); }
  }

  Future<void> finishServiceOrder(int idOrden) async {
    _setLoading(true); _setError(null);
    try { 
      await _repository.updateServiceOrder(idOrden, {'estado_orden': 'LISTO_PARA_ENTREGA'}); 
      await fetchServiceOrders(); 
      await fetchStats();
    }
    catch (e) { _setError(e.toString()); rethrow; }
    finally { _setLoading(false); }
  }

  Future<void> deliverServiceOrder(int idOrden) async {
    _setLoading(true); _setError(null);
    try { 
      await _repository.updateServiceOrder(idOrden, {'estado_orden': 'ENTREGADO'}); 
      await fetchServiceOrders(); 
      await fetchStats();
    }
    catch (e) { _setError(e.toString()); rethrow; }
    finally { _setLoading(false); }
  }

  Future<void> updateOrderReport(int idOrden, String informeTrabajo) async {
    _setLoading(true); _setError(null);
    try { 
      await _repository.updateServiceOrder(idOrden, {'informe_trabajo': informeTrabajo}); 
      await fetchServiceOrders(); 
    }
    catch (e) { _setError(e.toString()); rethrow; }
    finally { _setLoading(false); }
  }

  Future<Map<String, dynamic>> findVehicleByPlate(String placa) async {
    _setLoading(true); _setError(null);
    try {
      return await _repository.getVehicleByPlate(placa);
    } catch (e) {
      _setError(e.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  List<dynamic> _receipts = [];
  List<dynamic> get receipts => _receipts;

  Future<void> fetchReceipts() async {
    _setLoading(true); _setError(null);
    try {
      _receipts = await _repository.getAllReceipts();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> createReceipt(Map<String, dynamic> data) async {
    _setLoading(true); _setError(null);
    try {
      await _repository.createReceipt(data);
      await fetchReceipts();
    } catch (e) {
      _setError(e.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateReceipt(int id, Map<String, dynamic> data) async {
    _setLoading(true); _setError(null);
    try {
      await _repository.updateReceipt(id, data);
      await fetchReceipts();
    } catch (e) {
      _setError(e.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteReceipt(int id) async {
    _setLoading(true); _setError(null);
    try {
      await _repository.deleteReceipt(id);
      _receipts.removeWhere((r) => r['id_recibo'] == id);
    } catch (e) {
      _setError(e.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> finalizeReceipt(int id) async {
    _setLoading(true); _setError(null);
    try {
      await _repository.finalizeReceipt(id);
      await fetchReceipts();
    } catch (e) {
      _setError(e.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateUser(int id, Map<String, dynamic> data) async {
    _setLoading(true); _setError(null);
    try {
      await _repository.updateUser(id, data);
      await fetchUsers();
    } catch (e) {
      _setError(e.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> createMechanic(Map<String, dynamic> data) async {
    _setLoading(true); _setError(null);
    try {
      await _repository.createMechanic(data);
      await fetchUsers();
    } catch (e) {
      _setError(e.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }
}
