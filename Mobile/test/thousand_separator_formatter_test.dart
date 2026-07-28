import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/utils/thousand_separator_formatter.dart';

void main() {
  test('formatThousandsValue groups digits with dots', () {
    expect(formatThousandsValue(1000), '1.000');
    expect(formatThousandsValue(12000), '12.000');
    expect(formatThousandsValue(123456), '123.456');
  });

  test('parseThousandsNumber removes display separators', () {
    expect(parseThousandsNumber('1.000'), 1000);
    expect(parseThousandsNumber('12.000'), 12000);
    expect(parseThousandsNumber('123.456'), 123456);
  });

  test('ThousandSeparatorInputFormatter formats while typing', () {
    const formatter = ThousandSeparatorInputFormatter();

    final value = formatter.formatEditUpdate(
      TextEditingValue.empty,
      const TextEditingValue(text: '12000'),
    );

    expect(value.text, '12.000');
    expect(value.selection.baseOffset, 6);
  });
}
