import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../providers/admin_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/service_order_model.dart';
import '../../../core/utils/pdf_generator.dart';
import '../../../core/utils/report_assets.dart';
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
    await context.read<AdminProvider>().fetchVehicleHistory(
      vehicle['placa'].toString(),
    );
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
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.green),
      );
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
            style: GoogleFonts.rajdhani(
              color: AppTheme.textColor(context),
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _searchController,
            style: TextStyle(color: AppTheme.textColor(context)),
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              hintText: 'Buscar por placa...',
              hintStyle: TextStyle(color: AppTheme.textMutedColor(context)),
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
          ),
          const SizedBox(height: 16),
          Expanded(
            child: vehicles.isEmpty
                ? const Center(
                    child: Text(
                      'No se encontraron vehículos.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    itemCount: vehicles.length,
                    itemBuilder: (context, index) {
                      final v = vehicles[index];
                      return Card(
                        color: AppTheme.cardColor(context),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: AppTheme.borderColor(context),
                          ),
                        ),
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: const Icon(
                            Icons.directions_car,
                            color: AppTheme.amber,
                          ),
                          title: Text(
                            v['placa']?.toString() ?? 'Sin Placa',
                            style: TextStyle(
                              color: AppTheme.textColor(context),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            '${v['marca']} ${v['modelo']} - ${v['tipo_vehiculo']}',
                            style: TextStyle(
                              color: AppTheme.textMutedColor(context),
                            ),
                          ),
                          trailing: Icon(
                            Icons.arrow_forward_ios,
                            color: AppTheme.textMutedColor(context),
                            size: 16,
                          ),
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
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.green),
      );
    }

    final history = provider.vehicleHistory;
    if (history == null) {
      return const Center(
        child: Text(
          'No se pudo cargar el historial.',
          style: TextStyle(color: Colors.redAccent),
        ),
      );
    }

    final vehiculo = history['vehiculo'];
    final List<dynamic> rawOrders = history['ordenes'] ?? [];

    // Usar los recibos que ya devuelve el backend en el historial del vehículo
    final List<dynamic> vehicleReceipts = history['recibos'] ?? [];
    final formatCurrency = NumberFormat.currency(locale: 'es_CO', symbol: '\$');

    return DefaultTabController(
      length: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.arrow_back,
                        color: AppTheme.textColor(context),
                      ),
                      onPressed: () => setState(() => _selectedVehicle = null),
                    ),
                    Text(
                      'Placa: ${vehiculo['placa']}',
                      style: GoogleFonts.rajdhani(
                        color: AppTheme.textColor(context),
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Card(
                  color: AppTheme.cardColor(context),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: AppTheme.borderColor(context)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Datos del Vehículo',
                          style: TextStyle(
                            color: AppTheme.amber,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Marca: ${vehiculo['marca']}',
                          style: TextStyle(color: AppTheme.textColor(context)),
                        ),
                        Text(
                          'Modelo: ${vehiculo['modelo']}',
                          style: TextStyle(color: AppTheme.textColor(context)),
                        ),
                        Text(
                          'Tipo: ${vehiculo['tipo_vehiculo']}',
                          style: TextStyle(color: AppTheme.textColor(context)),
                        ),
                        if (vehiculo['propietario_nombre'] != null)
                          Text(
                            'Propietario: ${vehiculo['propietario_nombre']}',
                            style: TextStyle(
                              color: AppTheme.textColor(context),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          TabBar(
            labelColor: AppTheme.primaryColor,
            unselectedLabelColor: AppTheme.textMutedColor(context),
            indicatorColor: AppTheme.primaryColor,
            tabs: const [
              Tab(text: 'Órdenes de Servicio'),
              Tab(text: 'Recibos'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                // Tab 1: Órdenes
                rawOrders.isEmpty
                    ? Center(
                        child: Text(
                          'Este vehículo no tiene órdenes de servicio.',
                          style: TextStyle(
                            color: AppTheme.textMutedColor(context),
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: rawOrders.length,
                        itemBuilder: (context, index) {
                          final order = rawOrders[index];
                          final report = ReportAssetParser.parse(
                            order['informe_trabajo']?.toString(),
                          );
                          return Card(
                            color: AppTheme.cardColor(context),
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: AppTheme.borderColor(context),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        order['numero_orden']?.toString() ??
                                            'Orden #${order['id_orden']}',
                                        style: TextStyle(
                                          color: AppTheme.textColor(context),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        order['estado_orden']?.toString() ?? '',
                                        style: const TextStyle(
                                          color: AppTheme.green,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Fecha Ingreso: ${order['fecha_ingreso']}',
                                    style: TextStyle(
                                      color: AppTheme.textMutedColor(context),
                                    ),
                                  ),
                                  if (order['fecha_salida'] != null)
                                    Text(
                                      'Fecha Salida: ${order['fecha_salida']}',
                                      style: TextStyle(
                                        color: AppTheme.textMutedColor(context),
                                      ),
                                    ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Cliente: ${order['cliente_nombre']} (C.C: ${order['cliente_identificacion']} / Tel: ${order['cliente_telefono']})',
                                    style: TextStyle(
                                      color: AppTheme.textColor(context),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Km Ingreso: ${order['kilometraje_ingreso']} | Combustible: ${order['nivel_combustible']}',
                                    style: TextStyle(
                                      color: AppTheme.textMutedColor(context),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Trabajos: ${order['trabajos_a_realizar']}',
                                    style: TextStyle(
                                      color: AppTheme.textColor(context),
                                    ),
                                  ),
                                  if (report.text.isNotEmpty ||
                                      report.hasImages)
                                    _buildReportSummary(context, report),
                                  const SizedBox(height: 12),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: ElevatedButton.icon(
                                      icon: const Icon(Icons.picture_as_pdf),
                                      label: const Text(
                                        'Descargar Orden (PDF)',
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.redAccent,
                                        foregroundColor: Colors.white,
                                      ),
                                      onPressed: () {
                                        final orderModel =
                                            ServiceOrderModel.fromJson(order);
                                        PdfGenerator.generateServiceOrderPdf(
                                          orderModel,
                                          null,
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                // Tab 2: Recibos
                vehicleReceipts.isEmpty
                    ? Center(
                        child: Text(
                          'Este vehículo no tiene recibos o cotizaciones.',
                          style: TextStyle(
                            color: AppTheme.textMutedColor(context),
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: vehicleReceipts.length,
                        itemBuilder: (context, index) {
                          final receipt = vehicleReceipts[index];
                          final isFinalizado =
                              receipt['estado'] == 'FINALIZADO';
                          return Card(
                            color: AppTheme.cardColor(context),
                            margin: const EdgeInsets.only(bottom: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: AppTheme.borderColor(context),
                              ),
                            ),
                            child: ListTile(
                              leading: Icon(
                                isFinalizado
                                    ? Icons.check_circle
                                    : Icons.edit_document,
                                color: isFinalizado
                                    ? Colors.green
                                    : Colors.orange,
                              ),
                              title: Text(
                                '${receipt['tipo_documento']} ${receipt['numero_recibo']}',
                                style: TextStyle(
                                  color: AppTheme.textColor(context),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                'Total: ${formatCurrency.format(receipt['total'])}',
                                style: TextStyle(
                                  color: AppTheme.textMutedColor(context),
                                ),
                              ),
                              trailing: isFinalizado
                                  ? IconButton(
                                      icon: const Icon(
                                        Icons.picture_as_pdf,
                                        color: Colors.redAccent,
                                      ),
                                      onPressed: () =>
                                          PdfGenerator.generateReceiptPdf(
                                            receipt,
                                          ),
                                    )
                                  : null,
                            ),
                          );
                        },
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportSummary(BuildContext context, ReportContent report) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (report.text.isNotEmpty)
            Text(
              'Informe: ${report.text}',
              style: TextStyle(color: AppTheme.textMutedColor(context)),
            ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.inputColor(context),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.borderColor(context)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  report.hasImages
                      ? Icons.image_outlined
                      : Icons.hide_image_outlined,
                  size: 16,
                  color: AppTheme.textMutedColor(context),
                ),
                const SizedBox(width: 6),
                Text(
                  report.hasImages
                      ? 'Tiene imagenes (${report.imageUrls.length})'
                      : 'Sin imagenes',
                  style: TextStyle(
                    color: AppTheme.textMutedColor(context),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
