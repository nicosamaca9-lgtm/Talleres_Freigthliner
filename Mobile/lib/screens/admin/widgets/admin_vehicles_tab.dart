import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
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
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Buscar por Placa',
                    hintText: 'Ej: ABC-123',
                    prefixIcon: Icon(Icons.search, color: Colors.white54),
                    border: OutlineInputBorder(),
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
                child: const Text('Buscar'),
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
                return const Center(
                  child: Text(
                    'Ingresa una placa para ver el historial',
                    style: TextStyle(color: Colors.white54),
                  ),
                );
              }

              final vehiculoData = provider.vehicleHistory!['vehiculo'];
              final ordenesData = provider.vehicleHistory!['ordenes'] as List<dynamic>;

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    color: AppTheme.surfaceColor,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Datos del Vehículo',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Divider(color: Colors.white24, height: 24),
                          _buildInfoRow('Placa', vehiculoData['placa']),
                          _buildInfoRow('Marca', vehiculoData['marca']),
                          _buildInfoRow('Modelo', vehiculoData['modelo']),
                          _buildInfoRow('Color', vehiculoData['color']),
                          _buildInfoRow('Tipo', vehiculoData['tipo_vehiculo']),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Historial de Órdenes de Servicio',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (ordenesData.isEmpty)
                    const Text(
                      'No hay órdenes registradas para este vehículo',
                      style: TextStyle(color: Colors.white54),
                    )
                  else
                    ...ordenesData.map((orden) {
                      return Card(
                        color: AppTheme.surfaceColor,
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(
                            'Orden #${orden['id_orden']} - ${orden['estado_orden']}',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            'Fecha Ingreso: ${orden['fecha_ingreso']}\nCliente: ${orden['cliente_nombre']}',
                            style: const TextStyle(color: Colors.white70),
                          ),
                          isThreeLine: true,
                          trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 16),
                          onTap: () {
                            // Dialog with order details
                            _showOrderDetails(context, orden);
                          },
                        ),
                      );
                    }),
                ],
              );
            },
          ),
        ),
      ],
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
            style: const TextStyle(color: Colors.white54, fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showOrderDetails(BuildContext context, dynamic orden) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        title: Text('Orden #${orden['id_orden']}', style: const TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildInfoRow('Cliente', orden['cliente_nombre']),
              _buildInfoRow('Teléfono', orden['cliente_telefono']),
              _buildInfoRow('Conductor', orden['conductor_nombre'] ?? 'No especificado'),
              const Divider(color: Colors.white24),
              _buildInfoRow('Ingreso', '${orden['fecha_ingreso']} ${orden['hora_ingreso']}'),
              _buildInfoRow('Salida', '${orden['fecha_salida'] ?? 'N/A'} ${orden['hora_salida'] ?? 'N/A'}'),
              const Divider(color: Colors.white24),
              _buildInfoRow('Kilometraje', orden['kilometraje_ingreso'].toString()),
              _buildInfoRow('Combustible', orden['nivel_combustible']),
              const Divider(color: Colors.white24),
              const Text('Trabajos a realizar:', style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold)),
              Text(orden['trabajos_a_realizar'] ?? '', style: const TextStyle(color: Colors.white)),
              const SizedBox(height: 8),
              const Text('Informe del Mecánico:', style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold)),
              Text(orden['informe_trabajo'] ?? 'Sin informe', style: const TextStyle(color: Colors.white)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }
}
