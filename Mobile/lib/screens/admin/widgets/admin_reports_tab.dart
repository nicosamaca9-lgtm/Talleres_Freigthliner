import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../providers/admin_provider.dart';
import '../../../core/theme/app_theme.dart';

class AdminReportsTab extends StatefulWidget {
  const AdminReportsTab({super.key});

  @override
  State<AdminReportsTab> createState() => _AdminReportsTabState();
}

class _AdminReportsTabState extends State<AdminReportsTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().fetchPendingReports();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.pendingReports.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        return RefreshIndicator(
          onRefresh: provider.fetchPendingReports,
          child: provider.pendingReports.isEmpty
              ? ListView(
                  children: const [
                    SizedBox(height: 100),
                    Center(
                      child: Text(
                        'No hay informes pendientes',
                        style: TextStyle(color: Colors.white70, fontSize: 18),
                      ),
                    ),
                  ],
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: provider.pendingReports.length,
                  itemBuilder: (context, index) {
                    final report = provider.pendingReports[index];
                    return Card(
                      color: AppTheme.surfaceColor,
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Informe #${report.idInformeTecnico} (Orden #${report.idOrden})',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildInfoRow('Fecha', DateFormat('dd/MM/yyyy HH:mm').format(report.fechaReporte)),
                            _buildInfoRow('Mecánico ID', report.idUsuario.toString()),
                            const Divider(color: Colors.white24, height: 24),
                            const Text(
                              'Diagnóstico:',
                              style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold),
                            ),
                            Text(report.diagnostico, style: const TextStyle(color: Colors.white)),
                            const SizedBox(height: 8),
                            const Text(
                              'Recomendaciones:',
                              style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold),
                            ),
                            Text(report.recomendaciones, style: const TextStyle(color: Colors.white)),
                            if (report.repuestosUsados != null && report.repuestosUsados!.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              const Text(
                                'Repuestos Usados:',
                                style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold),
                              ),
                              Text(report.repuestosUsados!, style: const TextStyle(color: Colors.white)),
                            ],
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    icon: const Icon(Icons.close),
                                    label: const Text('Rechazar'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppTheme.errorColor,
                                      side: const BorderSide(color: AppTheme.errorColor),
                                    ),
                                    onPressed: () => _showReviewDialog(context, report.idInformeTecnico, false),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    icon: const Icon(Icons.check),
                                    label: const Text('Aprobar'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                    ),
                                    onPressed: () => _showReviewDialog(context, report.idInformeTecnico, true),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              color: Colors.white54,
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showReviewDialog(BuildContext context, int idReport, bool isApprove) {
    final TextEditingController observationsController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        title: Text(isApprove ? 'Aprobar Informe' : 'Rechazar Informe', style: const TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isApprove
                  ? '¿Estás seguro de aprobar este informe?'
                  : 'Por favor, ingresa las observaciones para devolver el informe al mecánico:',
              style: const TextStyle(color: Colors.white70),
            ),
            if (!isApprove) ...[
              const SizedBox(height: 16),
              TextField(
                controller: observationsController,
                maxLines: 3,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Observaciones',
                  border: OutlineInputBorder(),
                ),
              ),
            ]
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isApprove ? Colors.green : AppTheme.errorColor,
            ),
            onPressed: () async {
              if (!isApprove && observationsController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Las observaciones son obligatorias para rechazar.')),
                );
                return;
              }

              Navigator.pop(dialogContext); // Close dialog

              final scaffoldMessenger = ScaffoldMessenger.of(context);
              final provider = context.read<AdminProvider>();

              try {
                await provider.reviewReport(
                  idReport,
                  isApprove ? 'APROBADO' : 'RECHAZADO',
                  isApprove ? null : observationsController.text.trim(),
                );
                
                await provider.fetchPendingReports(); // Refresh the list
                
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text(isApprove ? 'Informe aprobado' : 'Informe rechazado y devuelto'),
                    backgroundColor: isApprove ? Colors.green : AppTheme.errorColor,
                  ),
                );
              } catch (e) {
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text('Error: ${e.toString()}'),
                    backgroundColor: AppTheme.errorColor,
                  ),
                );
              }
            },
            child: Text(isApprove ? 'Aprobar' : 'Rechazar'),
          ),
        ],
      ),
    );
  }
}
