import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../providers/admin_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/service_order_model.dart';
import '../../../core/utils/pdf_generator.dart';
import 'package:intl/intl.dart';

class AdminReportsTab extends StatefulWidget {
  const AdminReportsTab({super.key});

  @override
  State<AdminReportsTab> createState() => _AdminReportsTabState();
}

class _AdminReportsTabState extends State<AdminReportsTab> {
  final TextEditingController _searchController = TextEditingController();
  dynamic _selectedVehicle;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().fetchAllVehicles();
      context.read<AdminProvider>().fetchReceipts();
    });
    _searchController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _selectVehicle(dynamic vehicle) async {
    setState(() {
      _selectedVehicle = vehicle;
    });
    await context.read<AdminProvider>().fetchVehicleHistory(vehicle['placa'].toString());
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminProvider>(
      builder: (context, provider, child) {
        if (_selectedVehicle != null) {
          return _buildVehicleHistory(context, provider);
        }
        return _buildVehicleList(context, provider);
      },
    );
  }

  Widget _buildVehicleList(BuildContext context, AdminProvider provider) {
    if (provider.isLoading && provider.allVehicles.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.green));
    }

    final query = _searchController.text.trim().toUpperCase();
    final vehicles = provider.allVehicles.where((v) {
      if (query.isEmpty) return true;
      final placa = v['placa'].toString().toUpperCase();
      return placa.contains(query);
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Historial de Vehículos',
            style: GoogleFonts.rajdhani(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _searchController,
            style: const TextStyle(color: Colors.white),
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              hintText: 'Buscar por placa...',
              hintStyle: const TextStyle(color: Colors.white54),
              prefixIcon: const Icon(Icons.search, color: Colors.white54),
              filled: true,
              fillColor: const Color(0xFF151515),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: vehicles.isEmpty
                ? const Center(child: Text('No se encontraron vehículos.', style: TextStyle(color: Colors.white70)))
                : ListView.builder(
                    itemCount: vehicles.length,
                    itemBuilder: (context, index) {
                      final v = vehicles[index];
                      return Card(
                        color: const Color(0xFF0A0A0A),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Color(0xFF242424))),
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: const Icon(Icons.directions_car, color: AppTheme.amber),
                          title: Text(v['placa']?.toString() ?? 'Sin Placa', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          subtitle: Text('${v['marca']} ${v['modelo']} - ${v['tipo_vehiculo']}', style: const TextStyle(color: Colors.white54)),
                          trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 16),
                          onTap: () => _selectVehicle(v),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleHistory(BuildContext context, AdminProvider provider) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.green));
    }

    final history = provider.vehicleHistory;
    if (history == null) {
      return const Center(child: Text('No se pudo cargar el historial.', style: TextStyle(color: Colors.redAccent)));
    }

    final vehiculo = history['vehiculo'];
    final List<dynamic> rawOrders = history['ordenes'] ?? [];
    
    final vehicleReceipts = provider.receipts.where((r) => r['placa'] == vehiculo['placa']).toList();
    final formatCurrency = NumberFormat.currency(locale: 'es_CO', symbol: '\$');

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => setState(() => _selectedVehicle = null),
              ),
              Text(
                'Placa: ${vehiculo['placa']}',
                style: GoogleFonts.rajdhani(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Card(
            color: const Color(0xFF151515),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Datos del Vehículo', style: TextStyle(color: AppTheme.amber, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('Marca: ${vehiculo['marca']}', style: const TextStyle(color: Colors.white)),
                  Text('Modelo: ${vehiculo['modelo']}', style: const TextStyle(color: Colors.white)),
                  Text('Tipo: ${vehiculo['tipo_vehiculo']}', style: const TextStyle(color: Colors.white)),
                  if (vehiculo['propietario_nombre'] != null)
                     Text('Propietario: ${vehiculo['propietario_nombre']}', style: const TextStyle(color: Colors.white)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Órdenes de Servicio', style: GoogleFonts.rajdhani(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Expanded(
            child: rawOrders.isEmpty
                ? const Text('Este vehículo no tiene órdenes de servicio.', style: TextStyle(color: Colors.white70))
                : ListView.builder(
                    itemCount: rawOrders.length,
                    itemBuilder: (context, index) {
                      final order = rawOrders[index];
                      return Card(
                        color: const Color(0xFF0A0A0A),
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Color(0xFF242424))),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    order['numero_orden']?.toString() ?? 'Orden #${order['id_orden']}',
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    order['estado_orden']?.toString() ?? '',
                                    style: const TextStyle(color: AppTheme.green, fontSize: 12),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text('Fecha Ingreso: ${order['fecha_ingreso']}', style: const TextStyle(color: Colors.white70)),
                              if (order['fecha_salida'] != null)
                                Text('Fecha Salida: ${order['fecha_salida']}', style: const TextStyle(color: Colors.white70)),
                              const SizedBox(height: 8),
                              Text('Cliente: ${order['cliente_nombre']} (C.C: ${order['cliente_identificacion']} / Tel: ${order['cliente_telefono']})', style: const TextStyle(color: Colors.white)),
                              const SizedBox(height: 4),
                              Text('Km Ingreso: ${order['kilometraje_ingreso']} | Combustible: ${order['nivel_combustible']}', style: const TextStyle(color: Colors.white70)),
                              const SizedBox(height: 8),
                              Text('Trabajos: ${order['trabajos_a_realizar']}', style: const TextStyle(color: Colors.white)),
                              if (order['informe_trabajo'] != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text('Informe: ${order['informe_trabajo']}', style: const TextStyle(color: Colors.white54)),
                                ),
                              const SizedBox(height: 12),
                              Align(
                                alignment: Alignment.centerRight,
                                child: ElevatedButton.icon(
                                  icon: const Icon(Icons.picture_as_pdf),
                                  label: const Text('Descargar Orden (PDF)'),
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                                  onPressed: () {
                                    final orderModel = ServiceOrderModel.fromJson(order);
                                    PdfGenerator.generateServiceOrderPdf(orderModel, null);
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 16),
          Text('Recibos y Cotizaciones', style: GoogleFonts.rajdhani(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Expanded(
            child: vehicleReceipts.isEmpty
                ? const Text('Este vehículo no tiene recibos o cotizaciones.', style: TextStyle(color: Colors.white70))
                : ListView.builder(
                    itemCount: vehicleReceipts.length,
                    itemBuilder: (context, index) {
                      final receipt = vehicleReceipts[index];
                      final isFinalizado = receipt['estado'] == 'FINALIZADO';
                      return Card(
                        color: const Color(0xFF0A0A0A),
                        margin: const EdgeInsets.only(bottom: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Color(0xFF242424))),
                        child: ListTile(
                          leading: Icon(isFinalizado ? Icons.check_circle : Icons.edit_document, color: isFinalizado ? Colors.green : Colors.orange),
                          title: Text('${receipt['tipo_documento']} ${receipt['numero_recibo']}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          subtitle: Text('Total: ${formatCurrency.format(receipt['total'])}', style: const TextStyle(color: Colors.white54)),
                          trailing: isFinalizado 
                              ? IconButton(
                                  icon: const Icon(Icons.picture_as_pdf, color: Colors.redAccent),
                                  onPressed: () => PdfGenerator.generateReceiptPdf(receipt),
                                ) 
                              : null,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
