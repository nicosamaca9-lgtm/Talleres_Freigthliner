import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  bool _isSaving = false;

  String _tipoDocumento = 'RECIBO';
  final _clienteNombreCtrl = TextEditingController();
  final _clienteNitCtrl = TextEditingController();
  final _clienteTelefonoCtrl = TextEditingController();
  final _clienteCorreoCtrl = TextEditingController();
  final _vendedorCtrl = TextEditingController();
  final _placaCtrl = TextEditingController();
  String _formaPago = 'Efectivo';
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
      _clienteCorreoCtrl.text = r['cliente_correo'] ?? '';
      _vendedorCtrl.text = r['vendedor'] ?? '';
      _placaCtrl.text = r['placa'] ?? '';
      _formaPago = r['forma_pago'] ?? 'Efectivo';
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
        if (vehicleData['propietario_cedula'] != null) {
          _clienteNitCtrl.text = vehicleData['propietario_cedula'];
        }
        if (vehicleData['propietario_telefono'] != null) {
          _clienteTelefonoCtrl.text = vehicleData['propietario_telefono'];
        }
        if (vehicleData['propietario_correo'] != null) {
          _clienteCorreoCtrl.text = vehicleData['propietario_correo'];
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Datos de vehículo cargados'), backgroundColor: Colors.green));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No se encontró el vehículo o ocurrió un error: $e'), backgroundColor: Colors.orange));
    }
  }

  Future<void> _saveDocument() async {
    if (_isSaving) return;
    if (_formKey.currentState!.validate()) {
      setState(() => _isSaving = true);
      final data = {
        'tipo_documento': _tipoDocumento,
        'cliente_nombre': _clienteNombreCtrl.text,
        'cliente_nit': _clienteNitCtrl.text,
        'cliente_telefono': _clienteTelefonoCtrl.text,
        'cliente_correo': _clienteCorreoCtrl.text,
        'cliente_direccion': 'AUTOPISTA HIGUERAS',
        'cliente_ciudad': 'DUITAMA, BOYACA',
        'vendedor': _vendedorCtrl.text,
        'placa': _placaCtrl.text,
        'forma_pago': _formaPago,
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
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Documento guardado'), backgroundColor: Colors.green));
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isSaving = false);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.errorColor));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isNarrow = MediaQuery.sizeOf(context).width < 600;
    return Scaffold(
      backgroundColor: AppTheme.bgColor(context),
      appBar: AppBar(
        backgroundColor: AppTheme.bgColor(context),
        foregroundColor: AppTheme.textColor(context),
        title: Text(widget.receipt == null ? 'Nuevo Documento' : 'Editar Documento', style: TextStyle(fontSize: isNarrow ? 16 : 20)),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
            child: isNarrow
              ? IconButton(
                  onPressed: _isSaving ? null : _saveDocument,
                  icon: _isSaving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryColor))
                      : const Icon(Icons.save, color: AppTheme.primaryColor),
                )
              : ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor, padding: const EdgeInsets.symmetric(horizontal: 16)),
                  onPressed: _isSaving ? null : _saveDocument,
                  icon: _isSaving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                      : const Icon(Icons.save, color: Colors.black),
                  label: const Text('Guardar', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                ),
          ),
          if (!isNarrow) const SizedBox(width: 8),
        ],
      ),
      body: Form(
        key: _formKey,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 600;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Card(
                color: AppTheme.cardColor(context),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Información General', style: TextStyle(color: AppTheme.textColor(context), fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      if (isMobile) ...[
                        DropdownButtonFormField<String>(
                          value: _tipoDocumento,
                          style: TextStyle(color: AppTheme.textColor(context)),
                          items: ['RECIBO', 'COTIZACION'].map((e) => DropdownMenuItem(value: e, child: Text(e, style: TextStyle(color: AppTheme.textColor(context))))).toList(),
                          onChanged: (val) => setState(() => _tipoDocumento = val!),
                          dropdownColor: AppTheme.inputColor(context),
                          decoration: InputDecoration(labelText: 'Tipo de Documento', labelStyle: TextStyle(color: AppTheme.textMutedColor(context))),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(child: _buildTextField(_placaCtrl, 'Placa', inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]'))], maxLength: 6, customValidator: (val) {
                                if (val == null || val.isEmpty) return 'Campo requerido';
                                if (!RegExp(r'^[A-Za-z]{3}[0-9]{3}$').hasMatch(val)) return 'Ej: ABC123';
                                return null;
                            })),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              onPressed: _searchVehicleAndFill,
                              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor, padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16)),
                              icon: const Icon(Icons.search, color: Colors.black),
                              label: const Text('Buscar', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ] else ...[
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: _tipoDocumento,
                                style: TextStyle(color: AppTheme.textColor(context)),
                                items: ['RECIBO', 'COTIZACION'].map((e) => DropdownMenuItem(value: e, child: Text(e, style: TextStyle(color: AppTheme.textColor(context))))).toList(),
                                onChanged: (val) => setState(() => _tipoDocumento = val!),
                                dropdownColor: AppTheme.inputColor(context),
                                decoration: InputDecoration(labelText: 'Tipo de Documento', labelStyle: TextStyle(color: AppTheme.textMutedColor(context))),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Row(
                                children: [
                                  Expanded(child: _buildTextField(_placaCtrl, 'Placa', inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]'))], maxLength: 6, customValidator: (val) {
                                    if (val == null || val.isEmpty) return 'Campo requerido';
                                    if (!RegExp(r'^[A-Za-z]{3}[0-9]{3}$').hasMatch(val)) return 'Ej: ABC123';
                                    return null;
                                  })),
                                  const SizedBox(width: 8),
                                  ElevatedButton.icon(
                                    onPressed: _searchVehicleAndFill,
                                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor, padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16)),
                                    icon: const Icon(Icons.search, color: Colors.black),
                                    label: const Text('Buscar', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 16),
                      if (isMobile) ...[
                        _buildTextField(_clienteNombreCtrl, 'Cliente Nombre'),
                        const SizedBox(height: 16),
                        _buildTextField(_clienteNitCtrl, 'NIT/C.C', keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly]),
                        const SizedBox(height: 16),
                        _buildTextField(_clienteTelefonoCtrl, 'Teléfono', keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly], customValidator: (val) {
                          if (val == null || val.isEmpty) return 'Campo requerido';
                          if (val.length != 10) return 'Debe tener 10 dígitos';
                          return null;
                        }),
                        const SizedBox(height: 16),
                        _buildTextField(_clienteCorreoCtrl, 'Correo Electrónico', keyboardType: TextInputType.emailAddress, customValidator: (val) => null),
                      ] else ...[
                        Row(
                          children: [
                            Expanded(child: _buildTextField(_clienteNombreCtrl, 'Cliente Nombre')),
                            const SizedBox(width: 16),
                            Expanded(child: _buildTextField(_clienteNitCtrl, 'NIT/C.C', keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly])),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(child: _buildTextField(_clienteTelefonoCtrl, 'Teléfono', keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly], customValidator: (val) {
                                if (val == null || val.isEmpty) return 'Campo requerido';
                                if (val.length != 10) return 'Debe tener 10 dígitos';
                                return null;
                            })),
                            const SizedBox(width: 16),
                            Expanded(child: _buildTextField(_clienteCorreoCtrl, 'Correo Electrónico', keyboardType: TextInputType.emailAddress, customValidator: (val) => null)),
                          ],
                        ),
                      ],
                      const SizedBox(height: 16),
                      if (isMobile) ...[
                        _buildTextField(_vendedorCtrl, 'Vendedor'),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: _formaPago.isNotEmpty && ['Efectivo', 'Transferencia'].contains(_formaPago) ? _formaPago : 'Efectivo',
                          style: TextStyle(color: AppTheme.textColor(context)),
                          items: ['Efectivo', 'Transferencia'].map((e) => DropdownMenuItem(value: e, child: Text(e, style: TextStyle(color: AppTheme.textColor(context))))).toList(),
                          onChanged: (val) => setState(() => _formaPago = val!),
                          dropdownColor: AppTheme.inputColor(context),
                          decoration: InputDecoration(
                            labelText: 'Forma de Pago', 
                            labelStyle: TextStyle(color: AppTheme.textMutedColor(context)),
                            filled: true,
                            fillColor: AppTheme.inputColor(context),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(_conceptoCtrl, 'Por Concepto De'),
                      ] else ...[
                        Row(
                          children: [
                            Expanded(child: _buildTextField(_vendedorCtrl, 'Vendedor')),
                            const SizedBox(width: 16),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: _formaPago.isNotEmpty && ['Efectivo', 'Transferencia'].contains(_formaPago) ? _formaPago : 'Efectivo',
                                style: TextStyle(color: AppTheme.textColor(context)),
                                items: ['Efectivo', 'Transferencia'].map((e) => DropdownMenuItem(value: e, child: Text(e, style: TextStyle(color: AppTheme.textColor(context))))).toList(),
                                onChanged: (val) => setState(() => _formaPago = val!),
                                dropdownColor: AppTheme.inputColor(context),
                                decoration: InputDecoration(
                                  labelText: 'Forma de Pago', 
                                  labelStyle: TextStyle(color: AppTheme.textMutedColor(context)),
                                  filled: true,
                                  fillColor: AppTheme.inputColor(context),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(flex: 2, child: _buildTextField(_conceptoCtrl, 'Por Concepto De')),
                          ],
                        ),
                      ],
                      const SizedBox(height: 16),
                      _buildTextField(_notaPieCtrl, 'Nota al pie'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              if (isMobile) ...[
                Text('Ítems (Servicios / Repuestos)', style: TextStyle(color: AppTheme.textColor(context), fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: ElevatedButton.icon(
                    onPressed: _addItem,
                    icon: Icon(Icons.add, color: AppTheme.textColor(context)),
                    label: Text('Añadir Ítem', style: TextStyle(color: AppTheme.textColor(context))),
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
                  ),
                ),
              ] else ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Ítems (Servicios / Repuestos)', style: TextStyle(color: AppTheme.textColor(context), fontSize: 20, fontWeight: FontWeight.bold)),
                    ElevatedButton.icon(
                      onPressed: _addItem,
                      icon: Icon(Icons.add, color: AppTheme.textColor(context)),
                      label: Text('Añadir Ítem', style: TextStyle(color: AppTheme.textColor(context))),
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
                    )
                  ],
                ),
              ],
              const SizedBox(height: 16),
              ..._items.asMap().entries.map((e) {
                int idx = e.key;
                Map<String, dynamic> item = e.value;
                return Card(
                  color: AppTheme.cardColor(context),
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: [
                          SizedBox(width: 250, child: _buildItemField(item, 'descripcion', 'Descripción', TextInputType.text, idx)),
                          const SizedBox(width: 12),
                          SizedBox(width: 80, child: _buildItemField(item, 'cantidad', 'Cant.', TextInputType.number, idx)),
                          const SizedBox(width: 12),
                          SizedBox(width: 120, child: _buildItemField(item, 'valor_unitario', 'Valor Unt.', TextInputType.number, idx)),
                          const SizedBox(width: 12),
                          SizedBox(width: 80, child: _buildItemField(item, 'porcentaje_iva', 'IVA %', TextInputType.number, idx)),
                          const SizedBox(width: 12),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.redAccent, size: 28),
                            onPressed: () => setState(() => _items.removeAt(idx)),
                          )
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ],
          ),
        );
      }),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, {TextInputType? keyboardType, List<TextInputFormatter>? inputFormatters, int? maxLength, String? Function(String?)? customValidator}) {
    return TextFormField(
      controller: controller,
      style: TextStyle(color: AppTheme.textColor(context)),
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      maxLength: maxLength,
      validator: customValidator ?? ((val) => val == null || val.isEmpty ? 'Campo requerido' : null),
      decoration: InputDecoration(
        counterText: '',
        labelText: label,
        labelStyle: TextStyle(color: AppTheme.textMutedColor(context)),
        filled: true,
        fillColor: AppTheme.inputColor(context),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildItemField(Map<String, dynamic> item, String key, String label, TextInputType type, int idx) {
    return TextFormField(
      initialValue: item[key].toString(),
      style: TextStyle(color: AppTheme.textColor(context)),
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
        labelStyle: TextStyle(color: AppTheme.textMutedColor(context)),
        filled: true,
        fillColor: AppTheme.inputColor(context),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
      ),
    );
  }
}
