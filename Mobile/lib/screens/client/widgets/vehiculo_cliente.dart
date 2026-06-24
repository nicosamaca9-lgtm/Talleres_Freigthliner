import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../../../widgets/ui_components.dart';
import '../../../providers/vehicle_provider.dart';
import '../../../models/vehicle_model.dart';
import 'vehicle_registration_dialog.dart';
import 'accept_invitation_dialog.dart';
import 'show_invitation_dialog.dart';

class VehiclesTab extends StatefulWidget {
  const VehiclesTab({super.key});

  @override
  State<VehiclesTab> createState() => _VehiclesTabState();
}

class _VehiclesTabState extends State<VehiclesTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VehicleProvider>().loadMyVehicles();
    });
  }

  void _showRegistrationDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => const VehicleRegistrationDialog(),
    );

    if (result == true && mounted) {
      context.read<VehicleProvider>().loadMyVehicles();
    }
  }

  void _showAcceptInvitationDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => const AcceptInvitationDialog(),
    );

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invitacion aceptada exitosamente'),
          backgroundColor: AppTheme.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Consumer<VehicleProvider>(
            builder: (context, provider, child) {
              if (provider.isLoading && provider.vehicles.isEmpty) {
                return const Center(
                  child: CircularProgressIndicator(color: AppTheme.green),
                );
              }

              if (provider.error != null && provider.vehicles.isEmpty) {
                return Center(
                  child: Text(
                    'Error: ${provider.error}',
                    style: GoogleFonts.dmSans(color: AppTheme.red),
                  ),
                );
              }

              List<Widget> vehicleCards = provider.vehicles.map((v) => _VehicleSummaryCard(vehicle: v)).toList();

              if (vehicleCards.isEmpty) {
                vehicleCards = [
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Text(
                        'No tienes vehículos registrados.',
                        style: GoogleFonts.dmSans(color: AppTheme.textMuted),
                      ),
                    ),
                  )
                ];
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 80.0), // Space for bottom buttons
                child: TabScaffold(
                  key: const ValueKey('vehicles'),
                  title: 'Mis vehiculos',
                  icon: Icons.directions_car_filled_rounded,
                  children: vehicleCards,
                ),
              );
            },
          ),
          Positioned(
            bottom: 20,
            right: 20,
            left: 20,
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _showAcceptInvitationDialog,
                    icon: const Icon(Icons.mail_outline, color: Colors.white, size: 20),
                    label: Text(
                      'Aceptar invitacion',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.dmSans(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF242424),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _showRegistrationDialog,
                    icon: const Icon(Icons.add, color: Colors.black, size: 20),
                    label: Text(
                      'Registrar Vehiculo',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.dmSans(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.green,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
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

class _VehicleSummaryCard extends StatelessWidget {
  const _VehicleSummaryCard({required this.vehicle});
  
  final VehicleModel vehicle;

  void _asignarConductor(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => ShowInvitationDialog(placa: vehicle.placa),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DashboardCard(
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 70,
                height: 70,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.directions_car_filled_rounded,
                  color: AppTheme.green,
                  size: 34,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${vehicle.marca} ${vehicle.modelo}',
                      style: GoogleFonts.rajdhani(
                        color: AppTheme.text,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Placa: ${vehicle.placa} - Tipo: ${vehicle.tipoVehiculo}',
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.dmSans(
                        color: AppTheme.textMuted,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 10),
                    StatusChip(
                      text: vehicle.rolVehiculo ?? 'Registrado', 
                      color: AppTheme.blue
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (vehicle.rolVehiculo == 'Propietario') ...[
            const SizedBox(height: 16),
            const Divider(color: Color(0xFF242424), height: 1),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _asignarConductor(context),
                  icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                  label: Text('Asignar conductor', style: GoogleFonts.dmSans()),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.green,
                    side: const BorderSide(color: AppTheme.green),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            )
          ]
        ],
      ),
    );
  }
}
