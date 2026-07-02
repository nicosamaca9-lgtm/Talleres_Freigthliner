class TechnicalReportModel {
  final int idInformeTecnico;
  final int idUsuario;
  final int idOrden;
  final DateTime fechaReporte;
  final String diagnostico;
  final String recomendaciones;
  final String? repuestosUsados;
  final String estadoRevision;
  final String? observacionesAdmin;

  TechnicalReportModel({
    required this.idInformeTecnico,
    required this.idUsuario,
    required this.idOrden,
    required this.fechaReporte,
    required this.diagnostico,
    required this.recomendaciones,
    this.repuestosUsados,
    required this.estadoRevision,
    this.observacionesAdmin,
  });

  factory TechnicalReportModel.fromJson(Map<String, dynamic> json) {
    return TechnicalReportModel(
      idInformeTecnico: json['id_informe_tecnico'] ?? 0,
      idUsuario: json['id_usuario'] ?? 0,
      idOrden: json['id_orden'] ?? 0,
      fechaReporte: DateTime.parse(json['fecha_reporte'] ?? DateTime.now().toIso8601String()),
      diagnostico: json['diagnostico'] ?? '',
      recomendaciones: json['recomendaciones'] ?? '',
      repuestosUsados: json['repuestos_usados'],
      estadoRevision: json['estado_revision'] ?? 'PENDIENTE',
      observacionesAdmin: json['observaciones_admin'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_informe_tecnico': idInformeTecnico,
      'id_usuario': idUsuario,
      'id_orden': idOrden,
      'fecha_reporte': fechaReporte.toIso8601String(),
      'diagnostico': diagnostico,
      'recomendaciones': recomendaciones,
      'repuestos_usados': repuestosUsados,
      'estado_revision': estadoRevision,
      'observaciones_admin': observacionesAdmin,
    };
  }
}
