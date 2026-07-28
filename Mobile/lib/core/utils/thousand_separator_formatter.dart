import 'package:flutter/services.dart';

String formatThousandsValue(Object? value) {
  if (value == null) return '';

  final rawValue = value is num
      ? value.truncate().toString()
      : value.toString();
  final digits = rawValue.replaceAll(RegExp(r'\D'), '');
  if (digits.isEmpty) return '';

  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    final positionFromRight = digits.length - i;
    buffer.write(digits[i]);
    if (positionFromRight > 1 && positionFromRight % 3 == 1) {
      buffer.write('.');
    }
  }

  return buffer.toString();
}

num parseThousandsNumber(String value) {
  final digits = value.replaceAll(RegExp(r'\D'), '');
  return num.tryParse(digits) ?? 0;
}

class ThousandSeparatorInputFormatter extends TextInputFormatter {
  const ThousandSeparatorInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final formatted = formatThousandsValue(newValue.text);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
