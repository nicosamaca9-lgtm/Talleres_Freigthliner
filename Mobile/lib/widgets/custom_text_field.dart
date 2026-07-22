import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_theme.dart';

class CustomTextField extends StatelessWidget {
  final String label;
  final String hintText;
  final bool obscureText;
  final TextInputType keyboardType;
  final TextEditingController? controller;
  final List<TextInputFormatter>? inputFormatters;
  final String? errorText;
  final int maxLines;
  final String? Function(String?)? validator;
  final bool readOnly;

  const CustomTextField({
    super.key,
    required this.label,
    required this.hintText,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.controller,
    this.inputFormatters,
    this.errorText,
    this.maxLines = 1,
    this.validator,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.dmSans(
            color: AppTheme.textMutedColor(context),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 5),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          maxLines: maxLines,
          validator: validator,
          readOnly: readOnly,
          style: GoogleFonts.dmSans(
            color: readOnly ? AppTheme.textMutedColor(context) : AppTheme.textColor(context),
            fontSize: 16,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            errorText: errorText,
            errorMaxLines: 3,
            errorStyle: GoogleFonts.dmSans(fontSize: 11),
          ),
        ),
      ],
    );
  }
}
