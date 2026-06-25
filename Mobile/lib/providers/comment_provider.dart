import 'package:flutter/material.dart';
import '../models/comment_model.dart';
import '../repositories/comment_repository.dart';

class CommentProvider extends ChangeNotifier {
  final CommentRepository _repository = CommentRepository();

  List<CommentModel> _comments = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<CommentModel> get comments => _comments;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadComments() async {
    _setLoading(true);
    _errorMessage = null;
    try {
      _comments = await _repository.getComments();
      _setLoading(false);
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _setLoading(false);
    }
  }

  Future<bool> createComment({
    required int idUsuario,
    required int rating,
    required String comentario,
  }) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      final newComment = await _repository.createComment(
        idUsuario: idUsuario,
        rating: rating,
        comentario: comentario,
      );
      _comments.insert(0, newComment);
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> updateComment({
    required int idComentario,
    int? rating,
    String? comentario,
  }) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      final updated = await _repository.updateComment(
        idComentario: idComentario,
        rating: rating,
        comentario: comentario,
      );
      final index = _comments.indexWhere((c) => c.idComentario == idComentario);
      if (index != -1) {
        _comments[index] = updated;
      }
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> deleteComment({required int idComentario}) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      await _repository.deleteComment(idComentario: idComentario);
      _comments.removeWhere((c) => c.idComentario == idComentario);
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _setLoading(false);
      return false;
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
