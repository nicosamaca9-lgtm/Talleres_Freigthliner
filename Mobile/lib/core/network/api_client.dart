import 'package:dio/dio.dart';
import '../storage/secure_storage.dart';

class ApiClient {
  static const String baseUrl = 'http://192.168.1.2:8000/api/v1';

  late final Dio dio;

  ApiClient() {
    dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await SecureStorage.getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) {
          // Manejo global de errores (opcional)
          return handler.next(e);
        },
      ),
    );
  }
}

// Instancia global
final apiClient = ApiClient().dio;
