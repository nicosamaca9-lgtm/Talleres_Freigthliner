// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vehicle_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VehicleModel _$VehicleModelFromJson(Map<String, dynamic> json) => VehicleModel(
      idVehiculo: (json['id_vehiculo'] as num).toInt(),
      placa: json['placa'] as String,
      marca: json['marca'] as String,
      modelo: json['modelo'] as String,
      tipoVehiculo: json['tipo_vehiculo'] as String,
      rolVehiculo: json['rol_vehiculo'] as String?,
    );

Map<String, dynamic> _$VehicleModelToJson(VehicleModel instance) =>
    <String, dynamic>{
      'id_vehiculo': instance.idVehiculo,
      'placa': instance.placa,
      'marca': instance.marca,
      'modelo': instance.modelo,
      'tipo_vehiculo': instance.tipoVehiculo,
      'rol_vehiculo': instance.rolVehiculo,
    };
