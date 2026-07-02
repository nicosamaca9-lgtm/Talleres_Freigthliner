class ServiceOrderModel {
  final int idOrden;
  final String numeroOrden;
  final int idVehiculo;
  final int? idMecanico;
  final int? idAgendamiento;
  final String fechaIngreso;
  final String horaIngreso;
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

  ServiceOrderModel({
    required this.idOrden,
    required this.numeroOrden,
    required this.idVehiculo,
    this.idMecanico,
    this.idAgendamiento,
    required this.fechaIngreso,
    required this.horaIngreso,
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
    );
  }
}
