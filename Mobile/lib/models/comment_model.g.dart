// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'comment_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CommentModel _$CommentModelFromJson(Map<String, dynamic> json) => CommentModel(
  idComentario: (json['id_comentario'] as num).toInt(),
  idUsuario: (json['id_usuario'] as num).toInt(),
  rating: (json['rating'] as num).toInt(),
  comentario: json['comentario'] as String,
  fechaRegistro: DateTime.parse(json['fecha_registro'] as String),
  usuario: UserModel.fromJson(json['usuario'] as Map<String, dynamic>),
);

Map<String, dynamic> _$CommentModelToJson(CommentModel instance) =>
    <String, dynamic>{
      'id_comentario': instance.idComentario,
      'id_usuario': instance.idUsuario,
      'rating': instance.rating,
      'comentario': instance.comentario,
      'fecha_registro': instance.fechaRegistro.toIso8601String(),
      'usuario': instance.usuario,
    };
