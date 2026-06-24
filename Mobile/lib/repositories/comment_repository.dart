import 'package:dio/dio.dart';
import '../core/network/api_client.dart';
import '../models/comment_model.dart';

class CommentRepository {
  Future<List<CommentModel>> getComments() async {
    try {
      final response = await apiClient.get('/comments/');
      if (response.data is List) {
        return (response.data as List).map((e) => CommentModel.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      if (e is DioException) {
        throw Exception(e.response?.data['detail'] ?? 'Error al obtener comentarios');
      }
      throw Exception('Error inesperado');
    }
  }

  Future<CommentModel> createComment({
    required int idUsuario,
    required int rating,
    required String comentario,
  }) async {
    try {
      final response = await apiClient.post('/comments/', data: {
        'id_usuario': idUsuario,
        'rating': rating,
        'comentario': comentario,
      });
      return CommentModel.fromJson(response.data);
    } catch (e) {
      if (e is DioException) {
        throw Exception(e.response?.data['detail'] ?? 'Error al crear comentario');
      }
      throw Exception('Error inesperado');
    }
  }

  Future<CommentModel> updateComment({
    required int idComentario,
    int? rating,
    String? comentario,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (rating != null) data['rating'] = rating;
      if (comentario != null) data['comentario'] = comentario;

      final response = await apiClient.patch('/comments/$idComentario', data: data);
      return CommentModel.fromJson(response.data);
    } catch (e) {
      if (e is DioException) {
        throw Exception(e.response?.data['detail'] ?? 'Error al actualizar comentario');
      }
      throw Exception('Error inesperado');
    }
  }
}
