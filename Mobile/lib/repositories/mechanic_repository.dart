import 'package:dio/dio.dart';
import '../core/network/api_client.dart';
import '../models/service_order_model.dart';

class MechanicRepository {
  Future<List<ServiceOrderModel>> getMyAssignedOrders(int mechanicId) async {
    try {
      // Usaremos el endpoint general de admin por ahora, filtrando localmente
      // idealmente, el backend tendría un /mechanic/{id}/orders
      final response = await apiClient.get('/service-orders/');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        final orders = data.map((json) => ServiceOrderModel.fromJson(json)).toList();
        return orders.where((o) => o.idMecanico == mechanicId && o.estadoOrden != 'ENTREGADO').toList();
      }
      return [];
    } catch (e) {
      throw Exception('Error al obtener órdenes asignadas');
    }
  }
}
