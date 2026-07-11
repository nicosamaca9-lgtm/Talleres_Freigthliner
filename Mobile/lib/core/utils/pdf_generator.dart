import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../models/service_order_model.dart';
import '../../models/user_model.dart';

class PdfGenerator {
  static Future<void> generateServiceOrderPdf(ServiceOrderModel order, UserModel? mechanic) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(
                level: 0,
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('TF CENTRO AUTOMOTRIZ', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                    pw.Text('Orden: ${order.numeroOrden}', style: pw.TextStyle(fontSize: 20)),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),
              
              pw.Text('Datos del Cliente', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.Divider(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Nombre: ${order.clienteNombre}'),
                  pw.Text('Identificación: ${order.clienteIdentificacion}'),
                  pw.Text('Teléfono: ${order.clienteTelefono}'),
                ]
              ),
              if (order.conductorNombre != null) ...[
                pw.SizedBox(height: 10),
                pw.Text('Conductor: ${order.conductorNombre} (Tel: ${order.conductorTelefono ?? "N/A"})'),
              ],
              pw.SizedBox(height: 20),

              pw.Text('Datos del Vehículo y Recepción', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.Divider(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Vehículo ID: ${order.idVehiculo}'),
                  pw.Text('Kilometraje: ${order.kilometrajeIngreso} km'),
                  pw.Text('Combustible: ${order.nivelCombustible}'),
                ]
              ),
              pw.SizedBox(height: 10),
              pw.Text('Fecha de Ingreso: ${order.fechaIngreso} ${order.horaIngreso}'),
              pw.SizedBox(height: 20),

              pw.Text('Diagnóstico / Trabajos Solicitados', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.Divider(),
              pw.Text(order.trabajosARealizar),
              pw.SizedBox(height: 20),

              pw.Text('Informe Técnico (Mecánico)', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.Divider(),
              pw.Text('Mecánico asignado: ${mechanic?.nombreCompleto ?? "No asignado"}'),
              pw.SizedBox(height: 10),
              pw.Text(order.informeTrabajo ?? 'Sin informe registrado.'),
              
              pw.Spacer(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  pw.Column(
                    children: [
                      pw.Container(width: 150, height: 1, color: PdfColors.black),
                      pw.SizedBox(height: 5),
                      pw.Text('Firma Administrador'),
                    ]
                  ),
                  pw.Column(
                    children: [
                      pw.Container(width: 150, height: 1, color: PdfColors.black),
                      pw.SizedBox(height: 5),
                      pw.Text('Firma Cliente / Conductor'),
                    ]
                  ),
                ]
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Orden_Servicio_${order.numeroOrden}.pdf',
    );
  }

  static Future<void> generateReceiptPdf(Map<String, dynamic> receipt) async {
    final pdf = pw.Document();
    
    final items = (receipt['items'] as List<dynamic>?) ?? [];
    final List<List<String>> itemsData = [
      ['DESCRIPCION', 'CANTIDAD', 'VALOR UNT', 'IVA', 'TOTAL'],
      ...items.map((i) => [
        i['descripcion']?.toString() ?? '',
        i['cantidad']?.toString() ?? '0',
        i['valor_unitario']?.toString() ?? '0',
        '${i['porcentaje_iva']}%',
        i['total']?.toString() ?? '0',
      ])
    ];

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(
                level: 0,
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('TF CENTRO AUTOMOTRIZ', style: pw.TextStyle(color: PdfColors.black, fontSize: 24, fontWeight: pw.FontWeight.bold)),
                    pw.Text('${receipt['tipo_documento']} ${receipt['numero_recibo']}', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Table.fromTextArray(
                context: context,
                border: pw.TableBorder.all(color: PdfColors.black, width: 1),
                headerAlignment: pw.Alignment.centerLeft,
                cellAlignment: pw.Alignment.centerLeft,
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                data: <List<String>>[
                  ['CLIENTE', receipt['cliente_nombre'] ?? '', 'POR CONCEPTO DE'],
                  ['NIT/C.C', receipt['cliente_nit'] ?? '', receipt['concepto'] ?? ''],
                  ['DIRECCION', receipt['cliente_direccion'] ?? '', ''],
                  ['CIUDAD', receipt['cliente_ciudad'] ?? '', ''],
                  ['TELEFONO', receipt['cliente_telefono'] ?? '', 'PLACA: ${receipt['placa'] ?? ''}'],
                  ['VENDEDOR', receipt['vendedor'] ?? '', 'FECHA DOC: ${receipt['fecha_emision']?.split('T')[0] ?? ''}'],
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Table.fromTextArray(
                context: context,
                border: pw.TableBorder.all(color: PdfColors.black, width: 1),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                data: itemsData,
              ),
              pw.SizedBox(height: 20),
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Text(
                  'SUBTOTAL: \$${receipt['subtotal']}\nIVA: \$${receipt['iva_total']}\nTOTAL: \$${receipt['total']}', 
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)
                ),
              ),
              pw.SizedBox(height: 40),
              pw.Text('NOTA: ${receipt['nota_pie'] ?? ''}', style: const pw.TextStyle(fontSize: 10)),
              pw.Spacer(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  pw.Column(
                    children: [
                      pw.Container(width: 150, height: 1, color: PdfColors.black),
                      pw.SizedBox(height: 5),
                      pw.Text('Aceptado (Cliente)'),
                    ]
                  ),
                  pw.Column(
                    children: [
                      pw.Container(width: 150, height: 1, color: PdfColors.black),
                      pw.SizedBox(height: 5),
                      pw.Text('Firma Autorizada'),
                    ]
                  ),
                ]
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: '${receipt['tipo_documento']}_${receipt['numero_recibo']}.pdf',
    );
  }
}
