import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../core/theme/app_theme.dart';

class AdminReceiptsTab extends StatelessWidget {
  const AdminReceiptsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.receipt_long, size: 80, color: Colors.white54),
          const SizedBox(height: 16),
          const Text(
            'Recibos y Facturación',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Genera recibos y cotizaciones en PDF basados en las órdenes de servicio finalizadas.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            icon: const Icon(Icons.picture_as_pdf),
            label: const Text('Generar Recibo de Prueba (PDF)'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            onPressed: () => _generateTestPdf(context),
          ),
        ],
      ),
    );
  }

  Future<void> _generateTestPdf(BuildContext context) async {
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
                child: pw.Text('TF CENTRO AUTOMOTRIZ', style: pw.TextStyle(color: PdfColors.green800, fontSize: 24, fontWeight: pw.FontWeight.bold)),
              ),
              pw.SizedBox(height: 20),
              pw.Table.fromTextArray(
                context: context,
                border: pw.TableBorder.all(color: PdfColors.black, width: 1),
                headerAlignment: pw.Alignment.centerLeft,
                cellAlignment: pw.Alignment.centerLeft,
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                data: <List<String>>[
                  ['CLIENTE', 'INGECOLMAQ', 'POR CONCEPTO DE'],
                  ['NIT', '0000000', 'TRABAJO REALIZADO'],
                  ['DIRECCION', 'VENDEDOR', ''],
                  ['DUITAMA', '', ''],
                  ['FECHA DOC.', '2026-06-25', 'PLACA: ABC-123'],
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Table.fromTextArray(
                context: context,
                border: pw.TableBorder.all(color: PdfColors.black, width: 1),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                data: <List<String>>[
                  ['DESCRIPCION', 'CANTIDAD', 'VALOR UNT', 'IVA', 'TOTAL'],
                  ['ESCANEADA', '1', '50000', '19%', '50000'],
                  ['REVISION Y CAMBIO ARNES MOTOR', '1', '600000', '19%', '600000'],
                  ['LIMPIA CONTACTO', '1', '32000', '19%', '32000'],
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Text('SUBTOTAL: 682,000\nIVA: 129,580\nTOTAL: 811,580', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
              ),
              pw.SizedBox(height: 40),
              pw.Text('VALOR EN LETRAS: OCHOCIENTOS ONCE MIL QUINIENTOS OCHENTA PESOS M/C', style: const pw.TextStyle(fontSize: 10)),
              pw.Text('NOTA: COTIZACION VALIDA POR 15 DIAS', style: const pw.TextStyle(fontSize: 10)),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Recibo_Prueba_TF_Centro_Automotriz.pdf',
    );
  }
}
