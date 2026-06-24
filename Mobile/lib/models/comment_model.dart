import 'package:json_annotation/json_annotation.dart';
import 'user_model.dart';

part 'comment_model.g.dart';

@JsonSerializable()
class CommentModel {
  @JsonKey(name: 'id_comentario')
  final int idComentario;
  
  @JsonKey(name: 'id_usuario')
  final int idUsuario;
  
  final int rating;
  final String comentario;
  
  @JsonKey(name: 'fecha_registro')
  final DateTime fechaRegistro;
  
  final UserModel usuario;

  CommentModel({
    required this.idComentario,
    required this.idUsuario,
    required this.rating,
    required this.comentario,
    required this.fechaRegistro,
    required this.usuario,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) => _$CommentModelFromJson(json);
  Map<String, dynamic> toJson() => _$CommentModelToJson(this);
}
