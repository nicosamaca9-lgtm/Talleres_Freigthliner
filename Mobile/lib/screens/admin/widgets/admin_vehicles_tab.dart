import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/admin_provider.dart';
import '../../../core/theme/app_theme.dart';

class AdminVehiclesTab extends StatefulWidget {
  const AdminVehiclesTab({super.key});

  @override
  State<AdminVehiclesTab> createState() => _AdminVehiclesTabState();
}

class _AdminVehiclesTabState extends State<AdminVehiclesTab> {
  final TextEditingController _searchController = TextEditingController();

  void _search() {
    final placa = _searchController.text.trim();
    if (placa.isNotEmpty) {
      context.read<AdminProvider>().fetchVehicleHistory(placa);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  style: TextStyle(color: AppTheme.textColor(context)),
                  decoration: InputDecoration(
                    labelText: 'Buscar por Placa',
                    hintText: 'Ej: ABC-123',
                    labelStyle: TextStyle(color: AppTheme.textMutedColor(context)),
                    prefixIcon: Icon(Icons.search, color: AppTheme.textMutedColor(context)),
                    filled: true,
                    fillColor: AppTheme.inputColor(context),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppTheme.borderColor(context)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppTheme.borderColor(context)),
                    ),
                  ),
                  onSubmitted: (_) => _search(),
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                ),
                onPressed: _search,
                child: const Text('Buscar', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
        Expanded(
          child: Consumer<AdminProvider>(
            builder: (context, provider, child) {
              if (provider.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (provider.error != null) {
                return Center(
                  child: Text(
                    'Error: ${provider.error}',
                    style: const TextStyle(color: AppTheme.errorColor),
                  ),
                );
              }

              if (provider.vehicleHistory == null) {
                return Center(
                  child: Text(
                    'Ingresa una placa para ver el historial',
                    style: TextStyle(color: AppTheme.textMutedColor(context)),
                  ),
                );
              }

              final vehiculoData = provider.vehicleHistory!['vehiculo'];
              final ordenesData = provider.vehicleHistory!['ordenes'] as List<dynamic>? ?? [];
              final recibosData = provider.vehicleHistory!['recibos'] as List<dynamic>? ?? [];

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    color: AppTheme.cardColor(context),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: AppTheme.borderColor(context)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Datos del Vehículo',
                            style: TextStyle(
                              color: AppTheme.textColor(context),
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Divider(color: AppTheme.borderColor(context), height: 24),
                          _buildInfoRow(context, 'Placa', vehiculoData['placa']),
                          _buildInfoRow(context, 'Marca', vehiculoData['marca']),
                          _buildInfoRow(context, 'Modelo', vehiculoData['modelo']),
                          _buildInfoRow(context, 'Color', vehiculoData['color']),
                          _buildInfoRow(context, 'Tipo', vehiculoData['tipo_vehiculo']),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Historial de Órdenes de Servicio',
                    style: TextStyle(
                      color: AppTheme.textColor(context),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (ordenesData.isEmpty)
                    Text(
                      'No hay órdenes registradas para este vehículo',
                      style: TextStyle(color: AppTheme.textMutedColor(context)),
                    )
                  else
                    ...ordenesData.map((orden) {
                      return Card(
                        color: AppTheme.cardColor(context),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: AppTheme.borderColor(context)),
                        ),
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(
                            'Orden #${orden['id_orden']} - ${orden['estado_orden']}',
                            style: TextStyle(color: AppTheme.textColor(context), fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            'Fecha Ingreso: ${orden['fecha_ingreso']}\nCliente: ${orden['cliente_nombre']}',
                            style: TextStyle(color: AppTheme.textMutedColor(context)),
                          ),
                          isThreeLine: true,
                          trailing: Icon(Icons.arrow_forward_ios, color: AppTheme.textMutedColor(context), size: 16),
                          onTap: () {
                            _showOrderDetails(context, orden);
                          },
                        ),
                      );
                    }),
                  if (recibosData.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Historial de Recibos y Cotizaciones',
                      style: TextStyle(
                        color: AppTheme.textColor(context),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...recibosData.map((recibo) {
                      return Card(
                        color: AppTheme.cardColor(context),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: AppTheme.borderColor(context)),
                        ),
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(
                            '${recibo['tipo_documento']} #${recibo['numero_recibo']}',
                            style: TextStyle(color: AppTheme.textColor(context), fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            'Total: \$${recibo['total']} - ${recibo['estado']}',
                            style: TextStyle(color: AppTheme.textMutedColor(context)),
                          ),
                        ),
                      );
                    }),
                  ]
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: TextStyle(color: AppTheme.textMutedColor(context), fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: Text(value, style: TextStyle(color: AppTheme.textColor(context))),
          ),
        ],
      ),
    );
  }

  void _showOrderDetails(BuildContext context, dynamic orden) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.cardColor(context),
        title: Text('Orden #${orden['id_orden']}', style: TextStyle(color: AppTheme.textColor(context))),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildInfoRow(context, 'Cliente', orden['cliente_nombre']),
              _buildInfoRow(context, 'Teléfono', orden['cliente_telefono']),
              _buildInfoRow(context, 'Conductor', orden['conductor_nombre'] ?? 'No especificado'),
              Divider(color: AppTheme.borderColor(context)),
              _buildInfoRow(context, 'Ingreso', '${orden['fecha_ingreso']} ${orden['hora_ingreso']}'),
              _buildInfoRow(context, 'Salida', '${orden['fecha_salida'] ?? 'N/A'} ${orden['hora_salida'] ?? 'N/A'}'),
              Divider(color: AppTheme.borderColor(context)),
              _buildInfoRow(context, 'Kilometraje', orden['kilometraje_ingreso'].toString()),
              _buildInfoRow(context, 'Combustible', orden['nivel_combustible']),
              Divider(color: AppTheme.borderColor(context)),
              Text('Trabajos a realizar:', style: TextStyle(color: AppTheme.textMutedColor(context), fontWeight: FontWeight.bold)),
              Text(orden['trabajos_a_realizar'] ?? '', style: TextStyle(color: AppTheme.textColor(context))),
              const SizedBox(height: 8),
              Text('Informe del Mecánico:', style: TextStyle(color: AppTheme.textMutedColor(context), fontWeight: FontWeight.bold)),
              Text(orden['informe_trabajo'] ?? 'Sin informe', style: TextStyle(color: AppTheme.textColor(context))),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('Cerrar', style: TextStyle(color: AppTheme.textMutedColor(context))),
          ),
        ],
      ),
    );
  }
}
