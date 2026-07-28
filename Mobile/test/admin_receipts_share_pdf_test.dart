import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/providers/admin_provider.dart';
import 'package:mobile/screens/admin/widgets/admin_receipts_tab.dart';
import 'package:provider/provider.dart';

class FakeReceiptsProvider extends AdminProvider {
  @override
  bool get isLoading => false;

  @override
  List<dynamic> get receipts => [
    {
      'id_recibo': 9,
      'tipo_documento': 'RECIBO',
      'numero_recibo': 'REC-0009',
      'cliente_nombre': 'Luis',
      'placa': 'ABC123',
      'total': 119000,
      'estado': 'FINALIZADO',
    },
  ];

  @override
  Future<void> fetchReceipts() async {}
}

void main() {
  testWidgets('finalized receipt exposes share pdf action', (tester) async {
    Map<String, dynamic>? sharedReceipt;

    await tester.pumpWidget(
      ChangeNotifierProvider<AdminProvider>.value(
        value: FakeReceiptsProvider(),
        child: MaterialApp(
          home: Scaffold(
            body: AdminReceiptsTab(
              shareReceiptPdf: (receipt) async {
                sharedReceipt = receipt;
                return true;
              },
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('RECIBO REC-0009'));
    await tester.pumpAndSettle();

    expect(find.text('Descargar PDF'), findsOneWidget);
    expect(find.text('Compartir PDF'), findsOneWidget);

    await tester.tap(find.byKey(const Key('share_receipt_pdf_9')));
    await tester.pump();

    expect(sharedReceipt?['id_recibo'], 9);
    expect(sharedReceipt?['numero_recibo'], 'REC-0009');
  });
}
