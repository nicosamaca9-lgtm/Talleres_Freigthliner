class BookingModel {
  final int idAgendamiento;
  final int idUsuario;
  final int idVehiculo;
  final String fechaSolicitud;
  final DateTime fechaCita;
  final String horaCita;
  final String? observaciones;
  final String estadoConfirmacion;
  final String? motivoRechazo;

  BookingModel({
    required this.idAgendamiento,
    required this.idUsuario,
    required this.idVehiculo,
    required this.fechaSolicitud,
    required this.fechaCita,
    required this.horaCita,
    this.observaciones,
    required this.estadoConfirmacion,
    this.motivoRechazo,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      idAgendamiento: json['id_agendamiento'],
      idUsuario: json['id_usuario'],
      idVehiculo: json['id_vehiculo'],
      fechaSolicitud: json['fecha_solicitud'],
      fechaCita: DateTime.parse(json['fecha_cita']),
      horaCita: json['hora_cita'],
      observaciones: json['observaciones'],
      estadoConfirmacion: json['estado_confirmacion'],
      motivoRechazo: json['motivo_rechazo'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_agendamiento': idAgendamiento,
      'id_usuario': idUsuario,
      'id_vehiculo': idVehiculo,
      'fecha_solicitud': fechaSolicitud,
      'fecha_cita': fechaCita.toIso8601String().split('T').first,
      'hora_cita': horaCita,
      'observaciones': observaciones,
      'estado_confirmacion': estadoConfirmacion,
      'motivo_rechazo': motivoRechazo,
    };
  }

  DateTime get fechaHoraCita {
    try {
      return DateTime.parse('${fechaCita.toIso8601String().split('T').first}T$horaCita');
    } catch (_) {
      return DateTime.now();
    }
  }

  String get tipoServicio => 'Mantenimiento / Reparación';
  String? get notasAdicionales => observaciones;
}