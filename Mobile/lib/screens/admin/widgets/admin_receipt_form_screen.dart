import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../providers/admin_provider.dart';
import '../../../../core/theme/app_theme.dart';

class AdminReceiptFormScreen extends StatefulWidget {
  final Map<String, dynamic>? receipt;

  const AdminReceiptFormScreen({super.key, this.receipt});

  @override
  State<AdminReceiptFormScreen> createState() => _AdminReceiptFormScreenState();
}

class _AdminReceiptFormScreenState extends State<AdminReceiptFormScreen> {
  final _formKey = GlobalKey<FormState>();

  String _tipoDocumento = 'RECIBO';
  final _clienteNombreCtrl = TextEditingController();
  final _clienteNitCtrl = TextEditingController();
  final _clienteTelefonoCtrl = TextEditingController();
  final _clienteDireccionCtrl = TextEditingController();
  final _clienteCiudadCtrl = TextEditingController(text: 'DUITAMA');
  final _vendedorCtrl = TextEditingController();
  final _placaCtrl = TextEditingController();
  final _formaPagoCtrl = TextEditingController();
  final _conceptoCtrl = TextEditingController(text: 'TRABAJO REALIZADO');
  final _notaPieCtrl = TextEditingController(text: 'COTIZACION VALIDA POR 15 DIAS');

  List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    if (widget.receipt != null) {
      final r = widget.receipt!;
      _tipoDocumento = r['tipo_documento'] ?? 'RECIBO';
      _clienteNombreCtrl.text = r['cliente_nombre'] ?? '';
      _clienteNitCtrl.text = r['cliente_nit'] ?? '';
      _clienteTelefonoCtrl.text = r['cliente_telefono'] ?? '';
      _clienteDireccionCtrl.text = r['cliente_direccion'] ?? '';
      _clienteCiudadCtrl.text = r['cliente_ciudad'] ?? 'DUITAMA';
      _vendedorCtrl.text = r['vendedor'] ?? '';
      _placaCtrl.text = r['placa'] ?? '';
      _formaPagoCtrl.text = r['forma_pago'] ?? '';
      _conceptoCtrl.text = r['concepto'] ?? 'TRABAJO REALIZADO';
      _notaPieCtrl.text = r['nota_pie'] ?? 'COTIZACION VALIDA POR 15 DIAS';

      if (r['items'] != null) {
        _items = List<Map<String, dynamic>>.from(r['items'].map((i) => {
          'descripcion': i['descripcion'],
          'cantidad': i['cantidad'],
          'valor_unitario': i['valor_unitario'],
          'porcentaje_iva': i['porcentaje_iva'],
        }));
      }
    }
  }

  void _addItem() {
    setState(() {
      _items.add({
        'descripcion': '',
        'cantidad': 1,
        'valor_unitario': 0.0,
        'porcentaje_iva': 19.0,
      });
    });
  }

  Future<void> _searchVehicleAndFill() async {
    final placa = _placaCtrl.text.trim().toUpperCase();
    if (placa.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ingrese una placa primero'), backgroundColor: Colors.orange));
      return;
    }

    try {
      final vehicleData = await context.read<AdminProvider>().findVehicleByPlate(placa);
      setState(() {
        if (vehicleData['propietario_nombre'] != null) {
          _clienteNombreCtrl.text = vehicleData['propietario_nombre'];
        }
        if (vehicleData['propietario_identificacion'] != null) {
          _clienteNitCtrl.text = vehicleData['propietario_identificacion'];
        }
        if (vehicleData['propietario_telefono'] != null) {
          _clienteTelefonoCtrl.text = vehicleData['propietario_telefono'];
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Datos de vehículo cargados'), backgroundColor: Colors.green));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No se encontró el vehículo: $e'), backgroundColor: Colors.orange));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceColor,
        title: Text(widget.receipt == null ? 'Nuevo Documento' : 'Editar Documento'),
        actions: [
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(horizontal: 16)),
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                final data = {
                  'tipo_documento': _tipoDocumento,
                  'cliente_nombre': _clienteNombreCtrl.text,
                  'cliente_nit': _clienteNitCtrl.text,
                  'cliente_telefono': _clienteTelefonoCtrl.text,
                  'cliente_direccion': _clienteDireccionCtrl.text,
                  'cliente_ciudad': _clienteCiudadCtrl.text,
                  'vendedor': _vendedorCtrl.text,
                  'placa': _placaCtrl.text,
                  'forma_pago': _formaPagoCtrl.text,
                  'concepto': _conceptoCtrl.text,
                  'nota_pie': _notaPieCtrl.text,
                  'items': _items,
                };

                try {
                  if (widget.receipt == null) {
                    await context.read<AdminProvider>().createReceipt(data);
                  } else {
                    await context.read<AdminProvider>().updateReceipt(widget.receipt!['id_recibo'], data);
                  }
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Documento guardado'), backgroundColor: Colors.green));
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.errorColor));
                }
              }
            },
            icon: const Icon(Icons.save, color: Colors.white),
            label: const Text('Guardar', style: TextStyle(color: Colors.white)),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                color: AppTheme.surfaceColor,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Información General', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _tipoDocumento,
                              items: ['RECIBO', 'COTIZACION'].map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(color: Colors.white)))).toList(),
                              onChanged: (val) => setState(() => _tipoDocumento = val!),
                              dropdownColor: AppTheme.surfaceColor,
                              decoration: const InputDecoration(labelText: 'Tipo de Documento', labelStyle: TextStyle(color: Colors.white70)),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Row(
                              children: [
                                Expanded(child: _buildTextField(_placaCtrl, 'Placa')),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  onPressed: _searchVehicleAndFill,
                                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor, padding: const EdgeInsets.symmetric(vertical: 16)),
                                  child: const Icon(Icons.search, color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(child: _buildTextField(_clienteNombreCtrl, 'Cliente Nombre')),
                          const SizedBox(width: 16),
                          Expanded(child: _buildTextField(_clienteNitCtrl, 'NIT/C.C')),
                          const SizedBox(width: 16),
                          Expanded(child: _buildTextField(_clienteTelefonoCtrl, 'Teléfono')),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(child: _buildTextField(_clienteDireccionCtrl, 'Dirección')),
                          const SizedBox(width: 16),
                          Expanded(child: _buildTextField(_clienteCiudadCtrl, 'Ciudad')),
                          const SizedBox(width: 16),
                          Expanded(child: _buildTextField(_vendedorCtrl, 'Vendedor')),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(child: _buildTextField(_formaPagoCtrl, 'Forma de Pago')),
                          const SizedBox(width: 16),
                          Expanded(flex: 2, child: _buildTextField(_conceptoCtrl, 'Por Concepto De')),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(_notaPieCtrl, 'Nota al pie'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Ítems (Servicios / Repuestos)', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  ElevatedButton.icon(
                    onPressed: _addItem,
                    icon: const Icon(Icons.add, color: Colors.white),
                    label: const Text('Añadir Ítem', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
                  )
                ],
              ),
              const SizedBox(height: 16),
              ..._items.asMap().entries.map((e) {
                int idx = e.key;
                Map<String, dynamic> item = e.value;
                return Card(
                  color: AppTheme.surfaceColor,
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        Expanded(flex: 3, child: _buildItemField(item, 'descripcion', 'Descripción', TextInputType.text, idx)),
                        const SizedBox(width: 12),
                        Expanded(child: _buildItemField(item, 'cantidad', 'Cant.', TextInputType.number, idx)),
                        const SizedBox(width: 12),
                        Expanded(child: _buildItemField(item, 'valor_unitario', 'Valor Unt.', TextInputType.number, idx)),
                        const SizedBox(width: 12),
                        Expanded(child: _buildItemField(item, 'porcentaje_iva', 'IVA %', TextInputType.number, idx)),
                        const SizedBox(width: 12),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.redAccent, size: 28),
                          onPressed: () => setState(() => _items.removeAt(idx)),
                        )
                      ],
                    ),
                  ),
                );
              }).toList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      validator: (val) => val!.isEmpty ? 'Campo requerido' : null,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        filled: true,
        fillColor: AppTheme.bg,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildItemField(Map<String, dynamic> item, String key, String label, TextInputType type, int idx) {
    return TextFormField(
      initialValue: item[key].toString(),
      style: const TextStyle(color: Colors.white),
      keyboardType: type,
      onChanged: (val) {
        if (key == 'descripcion') {
          _items[idx][key] = val;
        } else {
          _items[idx][key] = num.tryParse(val) ?? 0;
        }
      },
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        filled: true,
        fillColor: AppTheme.bg,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
      ),
    );
  }
}
