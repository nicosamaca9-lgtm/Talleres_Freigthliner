import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/booking_model.dart';

class BookingRepository {
  // Nota: Usa '10.0.2.2' si estás en emulador Android, o tu IP local si pruebas en físico
  final String _baseUrl = 'http://10.0.2.2:8000/api/v1';

  Future<BookingModel?> getLatestBooking() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/bookings/'));
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (data.isNotEmpty) {
          // Tomamos el último agendamiento registrado
          return BookingModel.fromJson(data.last);
        }
      }
      return null;
    } catch (e) {
      print("Error en BookingRepository: $e");
      return null;
    }
  }
}