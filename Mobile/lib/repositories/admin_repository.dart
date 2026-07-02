import 'package:dio/dio.dart';
import '../core/network/api_client.dart';
import '../models/booking_model.dart';
import '../models/service_order_model.dart';
import '../models/technical_report_model.dart';
import '../models/user_model.dart';

class AdminRepository {
  Future<Map<String, dynamic>> getStats() async {
    try {
      final response = await apiClient.get('/admin/stats');
      return response.data;
    } catch (e) {
      throw _handleError(e, 'Error al obtener estadísticas');
    }
  }

  Future<List<BookingModel>> getAllBookings() async {
    try {
      final response = await apiClient.get('/admin/bookings');
      final List<dynamic> data = response.data;
      return data.map((json) => BookingModel.fromJson(json)).toList();
    } catch (e) {
      throw _handleError(e, 'Error al obtener citas');
    }
  }

  Future<List<TechnicalReportModel>> getPendingReports() async {
    try {
      final response = await apiClient.get('/admin/reports/pending');
      final List<dynamic> data = response.data;
      return data.map((json) => TechnicalReportModel.fromJson(json)).toList();
    } catch (e) {
      throw _handleError(e, 'Error al obtener informes pendientes');
    }
  }

  Future<BookingModel> confirmBooking(int idAgendamiento) async {
    try {
      final response = await apiClient.patch('/admin/bookings/$idAgendamiento/confirm');
      return BookingModel.fromJson(response.data);
    } catch (e) {
      throw _handleError(e, 'Error al confirmar la cita');
    }
  }

  Future<BookingModel> rejectBooking(int idAgendamiento, String motivoRechazo) async {
    try {
      final response = await apiClient.patch(
        '/admin/bookings/$idAgendamiento/reject',
        data: {'motivo_rechazo': motivoRechazo},
      );
      return BookingModel.fromJson(response.data);
    } catch (e) {
      throw _handleError(e, 'Error al rechazar cita');
    }
  }

  Future<ServiceOrderModel> assignMechanic(int idOrden, int idMecanico) async {
    try {
      final response = await apiClient.patch(
        '/admin/service-orders/$idOrden/assign',
        data: {'id_mecanico': idMecanico},
      );
      return ServiceOrderModel.fromJson(response.data);
    } catch (e) {
      throw _handleError(e, 'Error al asignar mecánico');
    }
  }

  Future<TechnicalReportModel> reviewReport(int idReport, String estado, String? observaciones) async {
    try {
      final response = await apiClient.patch(
        '/admin/reports/$idReport/review',
        data: {
          'estado_revision': estado,
          'observaciones_admin': observaciones,
        },
      );
      return TechnicalReportModel.fromJson(response.data);
    } catch (e) {
      throw _handleError(e, 'Error al revisar el informe');
    }
  }

  Future<List<UserModel>> getAllUsers() async {
    try {
      final response = await apiClient.get('/admin/users');
      final List<dynamic> data = response.data;
      return data.map((json) => UserModel.fromJson(json)).toList();
    } catch (e) {
      throw _handleError(e, 'Error al obtener usuarios');
    }
  }

  Future<void> deleteUser(int idUsuario) async {
    try {
      await apiClient.delete('/admin/users/$idUsuario');
    } catch (e) {
      throw _handleError(e, 'Error al eliminar usuario');
    }
  }

  Future<List<ServiceOrderModel>> getAllServiceOrders() async {
    try {
      final response = await apiClient.get('/service-orders/');
      final List<dynamic> data = response.data;
      return data.map((json) => ServiceOrderModel.fromJson(json)).toList();
    } catch (e) {
      throw _handleError(e, 'Error al obtener órdenes de servicio');
    }
  }

  Future<ServiceOrderModel> createServiceOrder(Map<String, dynamic> data) async {
    try {
      final response = await apiClient.post('/service-orders/', data: data);
      return ServiceOrderModel.fromJson(response.data);
    } catch (e) {
      throw _handleError(e, 'Error al crear orden de servicio');
    }
  }

  Future<Map<String, dynamic>> getVehicleHistory(String placa) async {
    try {
      final response = await apiClient.get('/admin/vehicles/$placa/history');
      return response.data;
    } catch (e) {
      throw _handleError(e, 'Error al obtener historial del vehículo');
    }
  }

  Future<ServiceOrderModel> updateServiceOrder(int idOrden, Map<String, dynamic> updateData) async {
    try {
      final response = await apiClient.patch('/service-orders/$idOrden', data: updateData);
      return ServiceOrderModel.fromJson(response.data);
    } catch (e) { throw _handleError(e, 'Error al actualizar orden de servicio'); }
  }

  Future<Map<String, dynamic>> getVehicleByPlate(String placa) async {
    try {
      final response = await apiClient.get('/vehicles/$placa');
      return response.data;
    } catch (e) { throw _handleError(e, 'Vehículo no encontrado'); }
  }

  Exception _handleError(dynamic e, String defaultMessage) {
    if (e is DioException) {
      return Exception(e.response?.data['detail'] ?? defaultMessage);
    }
    return Exception(defaultMessage);
  }
}
