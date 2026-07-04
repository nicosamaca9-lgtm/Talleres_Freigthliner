import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/admin_provider.dart';
import '../../../core/theme/app_theme.dart';
import 'admin_receipt_form_screen.dart';
import '../../../core/utils/pdf_generator.dart';
import 'package:intl/intl.dart';

class AdminReceiptsTab extends StatefulWidget {
  const AdminReceiptsTab({super.key});

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
          return (r['numero_recibo']?.toString().toLowerCase().contains(query) ?? false) ||
                 (r['placa']?.toString().toLowerCase().contains(query) ?? false) ||
                 (r['cliente_nombre']?.toString().toLowerCase().contains(query) ?? false);
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
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Buscar por N° Recibo, Placa o Cliente...',
                            hintStyle: const TextStyle(color: Colors.white54),
                            prefixIcon: const Icon(Icons.search, color: Colors.white54),
                            filled: true,
                            fillColor: AppTheme.surfaceColor,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          onChanged: (val) => setState(() => _searchQuery = val),
                        ),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.add),
                        label: const Text('Nuevo Documento'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                      final formatCurrency = NumberFormat.currency(locale: 'es_CO', symbol: '\$');

                      return Card(
                        color: AppTheme.surfaceColor,
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ExpansionTile(
                          iconColor: Colors.white,
                          collapsedIconColor: Colors.white54,
                          leading: CircleAvatar(
                            backgroundColor: isFinalizado ? Colors.green : Colors.orange,
                            child: Icon(isFinalizado ? Icons.check_circle : Icons.edit_document, color: Colors.white),
                          ),
                          title: Text(
                            '${receipt['tipo_documento']} ${receipt['numero_recibo']}',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            'Cliente: ${receipt['cliente_nombre']} | Placa: ${receipt['placa']}\nTotal: ${formatCurrency.format(receipt['total'])}',
                            style: const TextStyle(color: Colors.white54),
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  if (!isFinalizado) ...[
                                    ElevatedButton.icon(
                                      icon: const Icon(Icons.edit),
                                      label: const Text('Editar'),
                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                                      onPressed: () => _showReceiptDialog(context, receipt),
                                    ),
                                    const SizedBox(width: 8),
                                    ElevatedButton.icon(
                                      icon: const Icon(Icons.check),
                                      label: const Text('Finalizar'),
                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                      onPressed: () => _confirmFinalize(context, receipt['id_recibo']),
                                    ),
                                    const SizedBox(width: 8),
                                    ElevatedButton.icon(
                                      icon: const Icon(Icons.delete),
                                      label: const Text('Eliminar'),
                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                      onPressed: () => _confirmDelete(context, receipt['id_recibo']),
                                    ),
                                  ],
                                  if (isFinalizado)
                                    ElevatedButton.icon(
                                      icon: const Icon(Icons.picture_as_pdf),
                                      label: const Text('Descargar PDF'),
                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                                      onPressed: () => PdfGenerator.generateReceiptPdf(receipt),
                                    ),
                                ],
                              ),
                            )
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
        backgroundColor: AppTheme.surfaceColor,
        title: const Text('Finalizar Documento', style: TextStyle(color: Colors.white)),
        content: const Text(
          '¿Estás seguro de finalizar este documento? Una vez finalizado no podrá ser editado ni eliminado, y se podrá descargar en PDF.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () async {
              Navigator.pop(dialogContext);
              try {
                await context.read<AdminProvider>().finalizeReceipt(id);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Documento finalizado'), backgroundColor: Colors.green));
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.errorColor));
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
        backgroundColor: AppTheme.surfaceColor,
        title: const Text('Eliminar Documento', style: TextStyle(color: Colors.white)),
        content: const Text(
          '¿Estás seguro de eliminar este documento?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor),
            onPressed: () async {
              Navigator.pop(dialogContext);
              try {
                await context.read<AdminProvider>().deleteReceipt(id);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Documento eliminado'), backgroundColor: Colors.green));
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.errorColor));
              }
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}
