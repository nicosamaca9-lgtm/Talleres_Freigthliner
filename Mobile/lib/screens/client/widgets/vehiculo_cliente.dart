import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../../../widgets/ui_components.dart';
// Descomente estas líneas si su compañero creó estos componentes, o use los nativos que dejé abajo
// import '../../../widgets/custom_text_field.dart';
// import '../../../widgets/custom_button.dart';

class VehiclesTab extends StatefulWidget {
  const VehiclesTab({super.key});

  @override
  State<VehiclesTab> createState() => _VehiclesTabState();
}

class _VehiclesTabState extends State<VehiclesTab> {
  
  // Función para levantar el modal (ventana emergente)
  void _abrirModalRegistro(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF101010),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: const _FormularioVehiculoModal(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return TabScaffold(
      key: const ValueKey('vehicles'),
      title: 'Mis vehículos',
      icon: Icons.directions_car_filled_rounded,
      children: [
        // 1. Tarjeta para agregar un nuevo vehículo
        InkWell(
          onTap: () => _abrirModalRegistro(context),
          borderRadius: BorderRadius.circular(16),
          child: DashboardCard(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.add_circle_outline_rounded, color: AppTheme.green),
                const SizedBox(width: 10),
                Text(
                  'Registrar nuevo vehículo',
                  style: GoogleFonts.dmSans(
                    color: AppTheme.green,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        
        // 2. Aquí luego haremos un ListView.builder con el GET de la API
        // Por ahora dejamos uno de prueba usando sus datos de la base de datos
        const _VehicleSummaryCard(
          placa: 'HZZ123',
          marca: 'Hyundai',
          modelo: 'Creta',
          tipoVehiculo: 'particular',
        ),
        
        // Mantengo las tarjetas de su compañero por si le sirven para el flujo
        const ResponsiveCards(
          left: _WorkStatusCard(),
          right: _QuoteCard(),
        ),
      ],
    );
  }
}

// ==========================================
// MODAL CON EL FORMULARIO DE REGISTRO
// ==========================================
class _FormularioVehiculoModal extends StatefulWidget {
  const _FormularioVehiculoModal();

  @override
  State<_FormularioVehiculoModal> createState() => _FormularioVehiculoModalState();
}

class _FormularioVehiculoModalState extends State<_FormularioVehiculoModal> {
  final _formKey = GlobalKey<FormState>();
  final _placaController = TextEditingController();
  final _marcaController = TextEditingController();
  final _modeloController = TextEditingController();
  
  // Aquí controlamos el Enum
  String? _tipoSeleccionado;
  final List<String> _tiposPermitidos = ['camion', 'volqueta', 'patineta', 'mula', 'bus', 'otro'];

  @override
  void dispose() {
    _placaController.dispose();
    _marcaController.dispose();
    _modeloController.dispose();
    super.dispose();
  }

  void _guardarVehiculo() {
    if (_formKey.currentState!.validate()) {
      // Aquí conectaremos el POST al API en el siguiente paso
      final dataParaBackend = {
        "placa": _placaController.text.toUpperCase(),
        "marca": _marcaController.text,
        "modelo": _modeloController.text,
        "tipo_vehiculo": _tipoSeleccionado,
      };
      
      print("JSON listo para mandar sin errores 500: $dataParaBackend");
      Navigator.pop(context); // Cierra el modal
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Registrar Vehículo',
              style: GoogleFonts.rajdhani(
                color: AppTheme.text,
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 20),
            
            // Placa (Obliga mayúsculas visualmente y en lógica)
            TextFormField(
              controller: _placaController,
              textCapitalization: TextCapitalization.characters,
              style: GoogleFonts.dmSans(color: Colors.white),
              decoration: _inputDecoration('Placa (Ej. AAA123)'),
              validator: (v) => v!.isEmpty ? 'Requerido' : null,
            ),
            const SizedBox(height: 16),
            
            // Marca
            TextFormField(
              controller: _marcaController,
              style: GoogleFonts.dmSans(color: Colors.white),
              decoration: _inputDecoration('Marca (Ej. Kenworth)'),
              validator: (v) => v!.isEmpty ? 'Requerido' : null,
            ),
            const SizedBox(height: 16),
            
            // Modelo
            TextFormField(
              controller: _modeloController,
              style: GoogleFonts.dmSans(color: Colors.white),
              decoration: _inputDecoration('Modelo (Ej. T680)'),
              validator: (v) => v!.isEmpty ? 'Requerido' : null,
            ),
            const SizedBox(height: 16),
            
            // Tipo de Vehículo (El Dropdown que evita el error del Enum)
            DropdownButtonFormField<String>(
              value: _tipoSeleccionado,
              dropdownColor: const Color(0xFF1A1A1A),
              style: GoogleFonts.dmSans(color: Colors.white),
              decoration: _inputDecoration('Tipo de Vehículo'),
              items: _tiposPermitidos.map((tipo) {
                return DropdownMenuItem(
                  value: tipo, // Esto es lo que va al backend (minúscula)
                  child: Text(tipo.toUpperCase()), // Esto ve el cliente (mayúscula)
                );
              }).toList(),
              onChanged: (val) => setState(() => _tipoSeleccionado = val),
              validator: (v) => v == null ? 'Seleccione un tipo' : null,
            ),
            const SizedBox(height: 24),
            
            // Botón Guardar
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onTap: _guardarVehiculo,
                child: Text(
                  'Guardar',
                  style: GoogleFonts.dmSans(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: AppTheme.textMuted),
      filled: true,
      fillColor: const Color(0xFF1A1A1A),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.green),
      ),
    );
  }
}

// ==========================================
// TARJETA DE RESUMEN DE VEHÍCULO (Dinámica)
// ==========================================
class _VehicleSummaryCard extends StatelessWidget {
  final String placa;
  final String marca;
  final String modelo;
  final String tipoVehiculo;

  const _VehicleSummaryCard({
    required this.placa,
    required this.marca,
    required this.modelo,
    required this.tipoVehiculo,
  });

  @override
  Widget build(BuildContext context) {
    return DashboardCard(
      child: Row(
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
                  '$marca $modelo',
                  style: GoogleFonts.rajdhani(
                    color: AppTheme.text,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Placa: $placa',
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.dmSans(
                    color: AppTheme.textMuted,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 10),
                StatusChip(text: tipoVehiculo.toUpperCase(), color: AppTheme.blue),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ... (Mantenga las clases _WorkStatusCard y _QuoteCard de su código original aquí abajo)
class _WorkStatusCard extends StatelessWidget {
  const _WorkStatusCard();
  // ... su código existente
  @override
  Widget build(BuildContext context) {
    return Container(); // Reemplace por su código original
  }
}

class _QuoteCard extends StatelessWidget {
  const _QuoteCard();
  // ... su código existente
  @override
  Widget build(BuildContext context) {
    return Container(); // Reemplace por su código original
  }
}