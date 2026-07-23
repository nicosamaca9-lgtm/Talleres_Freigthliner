import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/utils/report_assets.dart';

void main() {
  test('parse strips image block from visible report text', () {
    final report = ReportAssetParser.parse(
      'Diagnostico: fuga\nRecomendaciones: revisar\n[IMAGENES]https://cdn.test/a.jpg[/IMAGENES]',
    );

    expect(report.text, 'Diagnostico: fuga\nRecomendaciones: revisar');
    expect(report.imageUrls, ['https://cdn.test/a.jpg']);
  });

  test('parse supports multiple comma separated image urls', () {
    final report = ReportAssetParser.parse(
      '[IMAGENES]https://cdn.test/a.jpg, https://cdn.test/b.jpg[/IMAGENES]',
    );

    expect(report.text, isEmpty);
    expect(report.imageUrls, [
      'https://cdn.test/a.jpg',
      'https://cdn.test/b.jpg',
    ]);
  });

  test('parse handles empty report safely', () {
    final report = ReportAssetParser.parse(null);

    expect(report.text, isEmpty);
    expect(report.imageUrls, isEmpty);
  });
}
