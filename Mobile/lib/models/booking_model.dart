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
  final String? clienteNombre;
  final String? clienteTelefono;
  final String? clienteCedula;
  final String? placaVehiculo;

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
    this.clienteNombre,
    this.clienteTelefono,
    this.clienteCedula,
    this.placaVehiculo,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      idAgendamiento: json['id_agendamiento'],
      idUsuario: json['id_usuario'],
      idVehiculo: json['id_vehiculo'],
      fechaSolicitud: json['fecha_solicitud'],
      fechaCita: json['fecha_cita'] != null ? DateTime.tryParse(json['fecha_cita'].toString()) ?? DateTime(2000) : DateTime(2000),
      horaCita: json['hora_cita']?.toString() ?? '00:00:00',
      observaciones: json['observaciones'],
      estadoConfirmacion: json['estado_confirmacion'],
      motivoRechazo: json['motivo_rechazo'],
      clienteNombre: json['cliente_nombre'],
      clienteTelefono: json['cliente_telefono'],
      clienteCedula: json['cliente_cedula'],
      placaVehiculo: json['placa_vehiculo'],
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
      'cliente_nombre': clienteNombre,
      'cliente_telefono': clienteTelefono,
      'cliente_cedula': clienteCedula,
      'placa_vehiculo': placaVehiculo,
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