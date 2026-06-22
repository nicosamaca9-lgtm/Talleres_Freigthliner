import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../providers/vehicle_provider.dart';
import '../../../../core/theme/app_theme.dart';

class ShowInvitationDialog extends StatefulWidget {
  final String placa;
  const ShowInvitationDialog({super.key, required this.placa});

  @override
  State<ShowInvitationDialog> createState() => _ShowInvitationDialogState();
}

class _ShowInvitationDialogState extends State<ShowInvitationDialog> {
  String? _codigoSecreto;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _generarCodigo();
  }

  Future<void> _generarCodigo() async {
    try {
      final provider = Provider.of<VehicleProvider>(context, listen: false);
      final code = await provider.generateInvitation(widget.placa);
      if (mounted) {
        setState(() {
          _codigoSecreto = code;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _copiarAlPortapapeles() {
    if (_codigoSecreto != null) {
      Clipboard.setData(ClipboardData(text: _codigoSecreto!)).then((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Codigo copiado al portapapeles'),
            backgroundColor: AppTheme.blue,
            duration: Duration(seconds: 2),
          ),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1A1A1A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Codigo de Invitacion',
              style: GoogleFonts.rajdhani(
                color: AppTheme.text,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'Comparte este codigo con el conductor que deseas asignar a la placa ${widget.placa}.',
              style: GoogleFonts.dmSans(
                color: AppTheme.textMuted,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            if (_isLoading)
              const Center(
                  child: CircularProgressIndicator(color: AppTheme.green))
            else if (_error != null)
              Center(
                child: Text(
                  _error!,
                  style: GoogleFonts.dmSans(color: AppTheme.red),
                  textAlign: TextAlign.center,
                ),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  color: const Color(0xFF242424),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF333333)),
                ),
                child: Center(
                  child: Text(
                    _codigoSecreto ?? '',
                    style: GoogleFonts.dmSans(
                      color: AppTheme.green,
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 8.0,
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 30),
            if (!_isLoading && _error == null)
              ElevatedButton.icon(
                onPressed: _copiarAlPortapapeles,
                icon: const Icon(Icons.copy, size: 18),
                label: Text(
                  'Copiar Codigo',
                  style: GoogleFonts.dmSans(fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text(
                'Cerrar',
                style: GoogleFonts.dmSans(
                    color: AppTheme.textMuted, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
