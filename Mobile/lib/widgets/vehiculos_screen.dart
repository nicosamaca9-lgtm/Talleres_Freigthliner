import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; 
import 'package:mobile/providers/vehicle_provider.dart'; 

class VehiculosScreen extends StatefulWidget { 
  const VehiculosScreen({super.key});

  @override
  State<VehiculosScreen> createState() => _VehiculosScreenState();
}

class _VehiculosScreenState extends State<VehiculosScreen> {
  
  @override
  void initState() {
    super.initState();
    Future.microtask(() => 
      Provider.of<VehicleProvider>(context, listen: false).fetchVehicleData(1)
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color cardColor = Color(0xFF1E1E1E);
    const Color primaryGreen = Color(0xFF00E676);

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Consumer<VehicleProvider>( 
        builder: (context, provider, child) {
          
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator(color: primaryGreen));
          }

          final data = provider.vehicleData;
          
          if (data == null) {
             return const Center(child: Text("No se encontraron vehículos", style: TextStyle(color: Colors.white)));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.directions_car, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text("Mis vehículos", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 16),
                
                // 1. TARJETA DE VEHÍCULO
                _buildVehicleCard(cardColor, primaryGreen, data),
                const SizedBox(height: 16),
                
                // 2. TARJETA DE ESTADO ACTUAL
                _buildStatusCard(cardColor, primaryGreen, data),
                const SizedBox(height: 16),
                
                // 3. TARJETA DE COTIZACIÓN PENDIENTE
                _buildQuoteCard(cardColor, primaryGreen, data),
              ],
            ),
          );
        },
      ),
    );
  }

  // --- 1. TARJETA DEL VEHÍCULO ---
  Widget _buildVehicleCard(Color cardColor, Color primaryGreen, Map<String, dynamic> data) {
    final v = data['vehiculo'] ?? data; 
    final marca = v['marca'] ?? 'Toyota';
    final modelo = v['modelo'] ?? 'Corolla';
    final anio = v['anio'] ?? '2020';
    final placa = v['placa'] ?? 'ACA-456';
    final kilometraje = v['kilometraje'] ?? '0';
    final estado = v['estado'] ?? 'En reparacion';
    final avance = ((v['avance_porcentaje'] ?? 0.72) * 100).toInt();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.grey[900], borderRadius: BorderRadius.circular(12)),
            child: Icon(Icons.directions_car, color: primaryGreen, size: 30),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("$marca $modelo", style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                Text(anio.toString(), style: const TextStyle(color: Colors.grey, fontSize: 14)),
                const SizedBox(height: 4),
                Text("Placa: $placa - KM: $kilometraje", style: const TextStyle(color: Colors.grey, fontSize: 13)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blueAccent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blueAccent.withOpacity(0.5)),
                  ),
                  child: Text(estado, style: const TextStyle(color: Colors.blueAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          Column(
            children: [
              const Text("Avance", style: TextStyle(color: Colors.grey, fontSize: 12)),
              Text("$avance%", style: TextStyle(color: primaryGreen, fontSize: 22, fontWeight: FontWeight.bold)),
            ],
          )
        ],
      ),
    );
  }

  // --- 2. TARJETA DE ESTADO ACTUAL ---
  Widget _buildStatusCard(Color cardColor, Color primaryGreen, Map<String, dynamic> data) {
    final orden = data['orden'] ?? {'codigo': 'OS-2026-088', 'trabajo': 'Cambio de correa de distribucion + aceite', 'progreso': 0.72, 'entrega': '7 Jun'};
    final progreso = (orden['progreso'] ?? 0.72) as double;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.autorenew, color: primaryGreen, size: 18),
              const SizedBox(width: 8),
              Text("Estado actual - ${orden['codigo']}", style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          Text(orden['trabajo'], style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          LinearProgressIndicator(value: progreso, backgroundColor: Colors.grey[800], color: primaryGreen, minHeight: 6),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("${(progreso * 100).toInt()}% completado", style: const TextStyle(color: Colors.grey, fontSize: 12)),
              Text("Entrega est.: ${orden['entrega']}", style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.download, size: 16, color: Colors.black),
                  label: const Text("Descargar OS", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(backgroundColor: primaryGreen, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.chat_bubble_outline, size: 16, color: Colors.white),
                  label: const Text("Chat", style: TextStyle(color: Colors.white)),
                  style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.grey), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  // --- 3. TARJETA DE COTIZACIÓN PENDIENTE ---
  Widget _buildQuoteCard(Color cardColor, Color primaryGreen, Map<String, dynamic> data) {
    final cotizacion = data['cotizacion'] ?? {'total': '\$165.000', 'items': [{'nombre': 'Filtro de aire', 'precio': '\$45.000'}, {'nombre': 'Pastillas de freno', 'precio': '\$120.000'}]};
    final List items = cotizacion['items'] ?? [];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.request_quote_outlined, color: Colors.amber, size: 18),
              SizedBox(width: 8),
              Text("Cotizacion pendiente", style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 4),
          const Text("Se requiere su aprobacion", style: TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 12),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(item['nombre'] ?? '', style: const TextStyle(color: Colors.grey, fontSize: 14)),
                Text(item['precio'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 14)),
              ],
            ),
          )),
          const Divider(color: Colors.grey, height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Total", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              Text(cotizacion['total'] ?? '\$0', style: TextStyle(color: primaryGreen, fontSize: 20, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.check, size: 16, color: Colors.white),
                  label: const Text("Aprobar", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700], shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.close, size: 16, color: Colors.white),
                  label: const Text("Rechazar", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red[700], shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}