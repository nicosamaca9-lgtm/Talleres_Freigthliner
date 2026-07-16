class ServiceOrderModel {
  final int idOrden;
  final String numeroOrden;
  final int idVehiculo;
  final int? idMecanico;
  final int? idAgendamiento;
  final String fechaIngreso;
  final String horaIngreso;
  final String? fechaSalida;
  final String? horaSalida;
  final String clienteNombre;
  final String clienteIdentificacion;
  final String clienteTelefono;
  final String? conductorNombre;
  final String? conductorTelefono;
  final int kilometrajeIngreso;
  final String nivelCombustible;
  final String trabajosARealizar;
  final String? informeTrabajo;
  final String estadoOrden;
  final String? placaVehiculo;
  final String? mecanicoNombre;

  ServiceOrderModel({
    required this.idOrden,
    required this.numeroOrden,
    required this.idVehiculo,
    this.idMecanico,
    this.idAgendamiento,
    required this.fechaIngreso,
    required this.horaIngreso,
    this.fechaSalida,
    this.horaSalida,
    required this.clienteNombre,
    required this.clienteIdentificacion,
    required this.clienteTelefono,
    this.conductorNombre,
    this.conductorTelefono,
    required this.kilometrajeIngreso,
    required this.nivelCombustible,
    required this.trabajosARealizar,
    this.informeTrabajo,
    required this.estadoOrden,
    this.placaVehiculo,
    this.mecanicoNombre,
  });

  factory ServiceOrderModel.fromJson(Map<String, dynamic> json) {
    return ServiceOrderModel(
      idOrden: json['id_orden'] ?? 0,
      numeroOrden: json['numero_orden']?.toString() ?? '',
      idVehiculo: json['id_vehiculo'] ?? 0,
      idMecanico: json['id_mecanico'],
      idAgendamiento: json['id_agendamiento'],
      fechaIngreso: json['fecha_ingreso']?.toString() ?? '',
      horaIngreso: json['hora_ingreso']?.toString() ?? '',
      fechaSalida: json['fecha_salida']?.toString(),
      horaSalida: json['hora_salida']?.toString(),
      clienteNombre: json['cliente_nombre']?.toString() ?? '',
      clienteIdentificacion: json['cliente_identificacion']?.toString() ?? '',
      clienteTelefono: json['cliente_telefono']?.toString() ?? '',
      conductorNombre: json['conductor_nombre']?.toString(),
      conductorTelefono: json['conductor_telefono']?.toString(),
      kilometrajeIngreso: json['kilometraje_ingreso'] ?? 0,
      nivelCombustible: json['nivel_combustible']?.toString() ?? '',
      trabajosARealizar: json['trabajos_a_realizar']?.toString() ?? 'Sin detalles',
      informeTrabajo: json['informe_trabajo']?.toString(),
      estadoOrden: json['estado_orden']?.toString() ?? 'EN_DIAGNOSTICO',
      placaVehiculo: json['placa_vehiculo']?.toString(),
      mecanicoNombre: json['mecanico_nombre']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_orden': idOrden,
      'numero_orden': numeroOrden,
      'id_vehiculo': idVehiculo,
      'id_mecanico': idMecanico,
      'id_agendamiento': idAgendamiento,
      'fecha_ingreso': fechaIngreso,
      'hora_ingreso': horaIngreso,
      'fecha_salida': fechaSalida,
      'hora_salida': horaSalida,
      'cliente_nombre': clienteNombre,
      'cliente_identificacion': clienteIdentificacion,
      'cliente_telefono': clienteTelefono,
      'conductor_nombre': conductorNombre,
      'conductor_telefono': conductorTelefono,
      'kilometraje_ingreso': kilometrajeIngreso,
      'nivel_combustible': nivelCombustible,
      'trabajos_a_realizar': trabajosARealizar,
      'informe_trabajo': informeTrabajo,
      'estado_orden': estadoOrden,
      'placa_vehiculo': placaVehiculo,
      'mecanico_nombre': mecanicoNombre,
    };
  }
}
