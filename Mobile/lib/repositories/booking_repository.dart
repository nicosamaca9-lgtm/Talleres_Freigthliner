import 'package:dio/dio.dart';
import '../core/network/api_client.dart';
import '../models/booking_model.dart';

class BookingRepository {
  Future<BookingModel?> getLatestBooking() async {
    try {
      final response = await apiClient.get('/bookings/');
      
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        if (data.isNotEmpty) {
          // Tomamos el último agendamiento registrado
          return BookingModel.fromJson(data.last);
        }
      }
      return null;
    } on DioException catch (e) {
      // Idealmente enviar a un log, pero en app móvil evitamos prints en prod
      return null;
    } catch (e) {
      return null;
    }
  }
}