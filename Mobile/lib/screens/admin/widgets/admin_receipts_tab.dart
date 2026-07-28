import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/admin_provider.dart';
import '../../../core/theme/app_theme.dart';
import 'admin_receipt_form_screen.dart';
import '../../../core/utils/pdf_generator.dart';
import 'package:intl/intl.dart';

typedef ReceiptPdfDownloadAction =
    Future<void> Function(Map<String, dynamic> receipt);
typedef ReceiptPdfShareAction =
    Future<bool> Function(Map<String, dynamic> receipt);

class AdminReceiptsTab extends StatefulWidget {
  const AdminReceiptsTab({
    super.key,
    this.downloadReceiptPdf,
    this.shareReceiptPdf,
  });

  final ReceiptPdfDownloadAction? downloadReceiptPdf;
  final ReceiptPdfShareAction? shareReceiptPdf;

  @override
  State<AdminReceiptsTab> createState() => _AdminReceiptsTabState();
}

class _AdminReceiptsTabState extends State<AdminReceiptsTab> {
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().fetchReceipts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.receipts.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        final filteredReceipts = provider.receipts.where((r) {
          final query = _searchQuery.toLowerCase();
          return (r['numero_recibo']?.toString().toLowerCase().contains(
                    query,
                  ) ??
                  false) ||
              (r['placa']?.toString().toLowerCase().contains(query) ?? false) ||
              (r['cliente_nombre']?.toString().toLowerCase().contains(query) ??
                  false);
        }).toList();

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: RefreshIndicator(
            onRefresh: provider.fetchReceipts,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          style: TextStyle(color: AppTheme.textColor(context)),
                          decoration: InputDecoration(
                            hintText:
                                'Buscar por N° Recibo, Placa o Cliente...',
                            hintStyle: TextStyle(
                              color: AppTheme.textMutedColor(context),
                            ),
                            prefixIcon: Icon(
                              Icons.search,
                              color: AppTheme.textMutedColor(context),
                            ),
                            filled: true,
                            fillColor: AppTheme.inputColor(context),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          onChanged: (val) =>
                              setState(() => _searchQuery = val),
                        ),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.add, color: Colors.black),
                        label: const Text(
                          'Nuevo Documento',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                        ),
                        onPressed: () => _showReceiptDialog(context, null),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filteredReceipts.length,
                    itemBuilder: (context, index) {
                      final receipt = filteredReceipts[index];
                      final isFinalizado = receipt['estado'] == 'FINALIZADO';
                      final formatCurrency = NumberFormat.currency(
                        locale: 'es_CO',
                        symbol: '\$',
                      );

                      return Card(
                        color: AppTheme.cardColor(context),
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ExpansionTile(
                          iconColor: AppTheme.textColor(context),
                          collapsedIconColor: AppTheme.textMutedColor(context),
                          leading: CircleAvatar(
                            backgroundColor: isFinalizado
                                ? Colors.green
                                : Colors.orange,
                            child: Icon(
                              isFinalizado
                                  ? Icons.check_circle
                                  : Icons.edit_document,
                              color: Colors.white,
                            ),
                          ),
                          title: Text(
                            '${receipt['tipo_documento']} ${receipt['numero_recibo']}',
                            style: TextStyle(
                              color: AppTheme.textColor(context),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            'Cliente: ${receipt['cliente_nombre']} | Placa: ${receipt['placa']}\nTotal: ${formatCurrency.format(receipt['total'])}',
                            style: TextStyle(
                              color: AppTheme.textMutedColor(context),
                            ),
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Wrap(
                                alignment: WrapAlignment.end,
                                spacing: 8.0,
                                runSpacing: 8.0,
                                children: [
                                  if (!isFinalizado) ...[
                                    ElevatedButton.icon(
                                      icon: const Icon(Icons.edit),
                                      label: const Text('Editar'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue,
                                        foregroundColor: Colors.white,
                                      ),
                                      onPressed: () =>
                                          _showReceiptDialog(context, receipt),
                                    ),
                                    ElevatedButton.icon(
                                      icon: const Icon(Icons.check),
                                      label: const Text('Finalizar'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        foregroundColor: Colors.white,
                                      ),
                                      onPressed: () => _confirmFinalize(
                                        context,
                                        receipt['id_recibo'],
                                      ),
                                    ),
                                    ElevatedButton.icon(
                                      icon: const Icon(Icons.delete),
                                      label: const Text('Eliminar'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                        foregroundColor: Colors.white,
                                      ),
                                      onPressed: () => _confirmDelete(
                                        context,
                                        receipt['id_recibo'],
                                      ),
                                    ),
                                  ],
                                  if (isFinalizado) ...[
                                    ElevatedButton.icon(
                                      key: Key(
                                        'download_receipt_pdf_${receipt['id_recibo']}',
                                      ),
                                      icon: const Icon(Icons.picture_as_pdf),
                                      label: const Text('Descargar PDF'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.redAccent,
                                        foregroundColor: Colors.white,
                                      ),
                                      onPressed: () =>
                                          _downloadReceiptPdf(context, receipt),
                                    ),
                                    OutlinedButton.icon(
                                      key: Key(
                                        'share_receipt_pdf_${receipt['id_recibo']}',
                                      ),
                                      icon: const Icon(Icons.share_outlined),
                                      label: const Text('Compartir PDF'),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: AppTheme.green,
                                        side: const BorderSide(
                                          color: AppTheme.green,
                                        ),
                                      ),
                                      onPressed: () =>
                                          _shareReceiptPdf(context, receipt),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _downloadReceiptPdf(
    BuildContext context,
    Map<String, dynamic> receipt,
  ) async {
    try {
      final action = widget.downloadReceiptPdf;
      if (action != null) {
        await action(receipt);
      } else {
        await PdfGenerator.generateReceiptPdf(receipt);
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al generar PDF: $e'),
          backgroundColor: AppTheme.red,
        ),
      );
    }
  }

  Future<void> _shareReceiptPdf(
    BuildContext context,
    Map<String, dynamic> receipt,
  ) async {
    try {
      final action = widget.shareReceiptPdf;
      final shared = action != null
          ? await action(receipt)
          : await PdfGenerator.shareReceiptPdf(receipt);

      if (!shared && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo abrir el panel de compartir.'),
            backgroundColor: AppTheme.amber,
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al compartir PDF: $e'),
          backgroundColor: AppTheme.red,
        ),
      );
    }
  }

  void _showReceiptDialog(BuildContext context, Map<String, dynamic>? receipt) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdminReceiptFormScreen(receipt: receipt),
      ),
    );
  }

  void _confirmFinalize(BuildContext context, int id) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.cardColor(context),
        title: Text(
          'Finalizar Documento',
          style: TextStyle(color: AppTheme.textColor(context)),
        ),
        content: Text(
          '¿Estás seguro de finalizar este documento? Una vez finalizado no podrá ser editado ni eliminado, y se podrá descargar en PDF.',
          style: TextStyle(color: AppTheme.textMutedColor(context)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Cancelar',
              style: TextStyle(color: AppTheme.textMutedColor(context)),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final adminProvider = context.read<AdminProvider>();
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              Navigator.pop(dialogContext);
              try {
                await adminProvider.finalizeReceipt(id);
                scaffoldMessenger.showSnackBar(
                  const SnackBar(
                    content: Text('Documento finalizado'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text('Error: $e'),
                    backgroundColor: AppTheme.errorColor,
                  ),
                );
              }
            },
            child: const Text('Finalizar'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, int id) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.cardColor(context),
        title: Text(
          'Eliminar Documento',
          style: TextStyle(color: AppTheme.textColor(context)),
        ),
        content: Text(
          '¿Estás seguro de eliminar este documento?',
          style: TextStyle(color: AppTheme.textMutedColor(context)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Cancelar',
              style: TextStyle(color: AppTheme.textMutedColor(context)),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final adminProvider = context.read<AdminProvider>();
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              Navigator.pop(dialogContext);
              try {
                await adminProvider.deleteReceipt(id);
                scaffoldMessenger.showSnackBar(
                  const SnackBar(
                    content: Text('Documento eliminado'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text('Error: $e'),
                    backgroundColor: AppTheme.errorColor,
                  ),
                );
              }
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}
