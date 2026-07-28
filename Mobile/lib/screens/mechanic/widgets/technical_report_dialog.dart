import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../widgets/custom_button.dart';
import '../../../widgets/custom_text_field.dart';
import '../../../providers/mechanic_provider.dart';
import '../../../providers/auth_provider.dart';

class TechnicalReportDialog extends StatefulWidget {
  final int idOrden;
  final String title;

  const TechnicalReportDialog({
    super.key,
    required this.idOrden,
    required this.title,
  });

  @override
  State<TechnicalReportDialog> createState() => _TechnicalReportDialogState();
}

class _TechnicalReportDialogState extends State<TechnicalReportDialog> {
  final _formKey = GlobalKey<FormState>();
  final _diagnosticoController = TextEditingController();
  final _recomendacionesController = TextEditingController();
  final _repuestosController = TextEditingController();

  List<String> _imagePaths = [];
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(source: source, imageQuality: 80);
      if (pickedFile != null) {
        setState(() {
          _imagePaths.add(pickedFile.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al seleccionar imagen: $e')),
      );
    }
  }

  void _removeImage(int index) {
    setState(() {
      _imagePaths.removeAt(index);
    });
  }

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardColor(context),
        title: Text('Confirmar entrega', style: TextStyle(color: AppTheme.textColor(context))),
        content: Text(
          '¿Estás seguro de entregar el informe? Una vez entregado no podrás editarlo y se notificará al administrador.\n\nTen en cuenta que si hay imágenes adjuntas, la subida puede tardar unos segundos.',
          style: TextStyle(color: AppTheme.textMutedColor(context)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar', style: TextStyle(color: Colors.red)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sí, entregar', style: TextStyle(color: AppTheme.green)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final mechanicProvider = context.read<MechanicProvider>();
    final authProvider = context.read<AuthProvider>();

    try {
      await mechanicProvider.submitTechnicalReport(
        idOrden: widget.idOrden,
        diagnostico: _diagnosticoController.text,
        recomendaciones: _recomendacionesController.text,
        repuestosUsados: _repuestosController.text,
        imagePaths: _imagePaths,
        mechanicId: authProvider.userId ?? 0,
      );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Informe enviado exitosamente')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _diagnosticoController.dispose();
    _recomendacionesController.dispose();
    _repuestosController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<MechanicProvider>().isLoading;

    return Dialog(
      backgroundColor: AppTheme.cardColor(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppTheme.borderColor(context)),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 800),
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  const Icon(Icons.note_add_rounded, color: AppTheme.green, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Redactar Informe: ${widget.title}',
                      style: GoogleFonts.rajdhani(
                        color: AppTheme.textColor(context),
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: isLoading ? null : () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close, color: AppTheme.textMutedColor(context)),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            Divider(color: AppTheme.borderColor(context), height: 1),
            // Form
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomTextField(
                        label: 'Diagnóstico',
                        controller: _diagnosticoController,
                        hintText: 'Describe el diagnóstico y trabajos realizados...',
                        maxLines: 4,
                        validator: (value) => value == null || value.isEmpty ? 'Requerido' : null,
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        label: 'Recomendaciones (Opcional)',
                        controller: _recomendacionesController,
                        hintText: 'Sugerencias para el cliente...',
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        label: 'Repuestos usados (Opcional)',
                        controller: _repuestosController,
                        hintText: 'Filtro de aceite, pastillas, etc...',
                        maxLines: 2,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Imágenes de repuestos (Opcional)',
                        style: GoogleFonts.dmSans(color: AppTheme.textColor(context), fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          ..._imagePaths.asMap().entries.map((entry) {
                            return Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: AppTheme.borderColor(context)),
                                    image: DecorationImage(
                                      image: FileImage(File(entry.value)),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: -8,
                                  right: -8,
                                  child: GestureDetector(
                                    onTap: () => _removeImage(entry.key),
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.close, size: 14, color: Colors.white),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }),
                          if (_imagePaths.length < 20) // Límite de 20 imágenes
                            GestureDetector(
                              onTap: () {
                                showModalBottomSheet(
                                  context: context,
                                  backgroundColor: AppTheme.cardColor(context),
                                  shape: const RoundedRectangleBorder(
                                    borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                                  ),
                                  builder: (ctx) => SafeArea(
                                    child: Wrap(
                                      children: [
                                        ListTile(
                                          leading: Icon(Icons.camera_alt, color: AppTheme.textColor(context)),
                                          title: Text('Tomar foto', style: TextStyle(color: AppTheme.textColor(context))),
                                          onTap: () {
                                            Navigator.pop(ctx);
                                            _pickImage(ImageSource.camera);
                                          },
                                        ),
                                        ListTile(
                                          leading: Icon(Icons.photo_library, color: AppTheme.textColor(context)),
                                          title: Text('Elegir de galería', style: TextStyle(color: AppTheme.textColor(context))),
                                          onTap: () {
                                            Navigator.pop(ctx);
                                            _pickImage(ImageSource.gallery);
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                              child: Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: AppTheme.green.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppTheme.green.withValues(alpha: 0.5), style: BorderStyle.solid),
                                ),
                                child: const Icon(Icons.add_a_photo, color: AppTheme.green),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Footer
            Divider(color: AppTheme.borderColor(context), height: 1),
            Padding(
              padding: const EdgeInsets.all(20),
              child: CustomButton(
                text: 'Entregar Informe',
                isLoading: isLoading,
                onPressed: () => _submitReport(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
