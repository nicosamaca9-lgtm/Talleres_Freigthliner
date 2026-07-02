class ReceiptItemModel {
  final int? idDetalle;
  final int? idRecibo;
  final String descripcion;
  final int cantidad;
  final double valorUnitario;
  final double porcentajeIva;
  final double total;

  ReceiptItemModel({
    this.idDetalle,
    this.idRecibo,
    required this.descripcion,
    required this.cantidad,
    required this.valorUnitario,
    required this.porcentajeIva,
    required this.total,
  });

  factory ReceiptItemModel.fromJson(Map<String, dynamic> json) {
    return ReceiptItemModel(
      idDetalle: json['id_detalle'],
      idRecibo: json['id_recibo'],
      descripcion: json['descripcion'],
      cantidad: json['cantidad'],
      valorUnitario: (json['valor_unitario'] as num).toDouble(),
      porcentajeIva: (json['porcentaje_iva'] as num).toDouble(),
      total: (json['total'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (idDetalle != null) 'id_detalle': idDetalle,
      if (idRecibo != null) 'id_recibo': idRecibo,
      'descripcion': descripcion,
      'cantidad': cantidad,
      'valor_unitario': valorUnitario,
      'porcentaje_iva': porcentajeIva,
      'total': total,
    };
  }
}

class ReceiptModel {
  final int? idRecibo;
  final int idOrden;
  final DateTime? fechaEmision;
  final DateTime? fechaVencimiento;
  final String clienteNombre;
  final String clienteNit;
  final String? clienteDireccion;
  final String clienteCiudad;
  final String? vendedor;
  final String placa;
  final String? formaPago;
  final String concepto;
  final double subtotal;
  final double ivaTotal;
  final double total;
  final String? valorEnLetras;
  final String notaPie;
  final List<ReceiptItemModel> items;

  ReceiptModel({
    this.idRecibo,
    required this.idOrden,
    this.fechaEmision,
    this.fechaVencimiento,
    required this.clienteNombre,
    required this.clienteNit,
    this.clienteDireccion,
    required this.clienteCiudad,
    this.vendedor,
    required this.placa,
    this.formaPago,
    required this.concepto,
    required this.subtotal,
    required this.ivaTotal,
    required this.total,
    this.valorEnLetras,
    required this.notaPie,
    required this.items,
  });

  factory ReceiptModel.fromJson(Map<String, dynamic> json) {
    return ReceiptModel(
      idRecibo: json['id_recibo'],
      idOrden: json['id_orden'],
      fechaEmision: json['fecha_emision'] != null ? DateTime.parse(json['fecha_emision']) : null,
      fechaVencimiento: json['fecha_vencimiento'] != null ? DateTime.parse(json['fecha_vencimiento']) : null,
      clienteNombre: json['cliente_nombre'],
      clienteNit: json['cliente_nit'],
      clienteDireccion: json['cliente_direccion'],
      clienteCiudad: json['cliente_ciudad'],
      vendedor: json['vendedor'],
      placa: json['placa'],
      formaPago: json['forma_pago'],
      concepto: json['concepto'],
      subtotal: (json['subtotal'] as num).toDouble(),
      ivaTotal: (json['iva_total'] as num).toDouble(),
      total: (json['total'] as num).toDouble(),
      valorEnLetras: json['valor_en_letras'],
      notaPie: json['nota_pie'],
      items: (json['items'] as List<dynamic>?)?.map((e) => ReceiptItemModel.fromJson(e)).toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (idRecibo != null) 'id_recibo': idRecibo,
      'id_orden': idOrden,
      if (fechaEmision != null) 'fecha_emision': fechaEmision!.toIso8601String(),
      if (fechaVencimiento != null) 'fecha_vencimiento': fechaVencimiento!.toIso8601String(),
      'cliente_nombre': clienteNombre,
      'cliente_nit': clienteNit,
      'cliente_direccion': clienteDireccion,
      'cliente_ciudad': clienteCiudad,
      'vendedor': vendedor,
      'placa': placa,
      'forma_pago': formaPago,
      'concepto': concepto,
      'subtotal': subtotal,
      'iva_total': ivaTotal,
      'total': total,
      'valor_en_letras': valorEnLetras,
      'nota_pie': notaPie,
      'items': items.map((e) => e.toJson()).toList(),
    };
  }
}
