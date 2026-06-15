class BookingModel {
  final int idAgendamiento;
  final int idUsuario;
  final int idVehiculo;
  final String fechaSolicitud;
  final String fechaCita;
  final String horaCita;
  final String? observaciones;
  final String estadoConfirmacion;

  BookingModel({
    required this.idAgendamiento,
    required this.idUsuario,
    required this.idVehiculo,
    required this.fechaSolicitud,
    required this.fechaCita,
    required this.horaCita,
    this.observaciones,
    required this.estadoConfirmacion,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      idAgendamiento: json['id_agendamiento'],
      idUsuario: json['id_usuario'],
      idVehiculo: json['id_vehiculo'],
      fechaSolicitud: json['fecha_solicitud'],
      fechaCita: json['fecha_cita'],
      horaCita: json['hora_cita'],
      observaciones: json['observaciones'],
      estadoConfirmacion: json['estado_confirmacion'] ?? 'PENDIENTE',
    );
  }
}