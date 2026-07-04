import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/admin_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/user_model.dart';

class AdminUsersTab extends StatefulWidget {
  const AdminUsersTab({super.key});

  @override
  State<AdminUsersTab> createState() => _AdminUsersTabState();
}

class _AdminUsersTabState extends State<AdminUsersTab> {
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().fetchUsers();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.users.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        final filteredUsers = provider.users.where((user) {
          final query = _searchQuery.toLowerCase();
          return user.nombreCompleto.toLowerCase().contains(query) ||
                 user.correoElectronico.toLowerCase().contains(query) ||
                 (user.cedula?.contains(query) ?? false);
        }).toList();

        return RefreshIndicator(
          onRefresh: provider.fetchUsers,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Buscar por nombre, correo o cédula...',
                          hintStyle: const TextStyle(color: Colors.white54),
                          prefixIcon: const Icon(Icons.search, color: Colors.white54),
                          filled: true,
                          fillColor: AppTheme.surfaceColor,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onChanged: (val) {
                          setState(() {
                            _searchQuery = val;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.person_add, color: Colors.white),
                      label: const Text('Añadir Mecánico', style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      ),
                      onPressed: () => _showCreateMechanicDialog(context),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filteredUsers.length,
                  itemBuilder: (context, index) {
                    final user = filteredUsers[index];
                    final isMechanic = user.rol == 'Tecnico';
                    final isAdmin = user.rol == 'Admin';
                    
                    return Card(
                      color: AppTheme.surfaceColor,
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isAdmin 
                              ? Colors.red 
                              : isMechanic ? Colors.orange : AppTheme.primaryColor,
                          child: Icon(
                            isAdmin ? Icons.admin_panel_settings : isMechanic ? Icons.build : Icons.person,
                            color: Colors.white,
                          ),
                        ),
                        title: Text(
                          user.nombreCompleto,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          '${user.correoElectronico}\nC.C: ${user.cedula} | Rol: ${user.rol}',
                          style: const TextStyle(color: Colors.white54),
                        ),
                        isThreeLine: true,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blueAccent),
                              onPressed: () => _showEditUserDialog(context, user),
                            ),
                            if (!isAdmin)
                              IconButton(
                                icon: const Icon(Icons.delete, color: AppTheme.errorColor),
                                onPressed: () => _confirmDelete(context, user.idUsuario, user.nombreCompleto),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showEditUserDialog(BuildContext context, UserModel user) {
    final nombreCtrl = TextEditingController(text: user.nombreCompleto.split(' ').first);
    final apellidoCtrl = TextEditingController(text: user.nombreCompleto.split(' ').skip(1).join(' '));
    final telefonoCtrl = TextEditingController(text: user.telefono);
    final cedulaCtrl = TextEditingController(text: user.cedula);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.bg,
        title: const Text('Editar Usuario', style: TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTextField(nombreCtrl, 'Nombre'),
              const SizedBox(height: 12),
              _buildTextField(apellidoCtrl, 'Apellido'),
              const SizedBox(height: 12),
              _buildTextField(telefonoCtrl, 'Teléfono'),
              const SizedBox(height: 12),
              _buildTextField(cedulaCtrl, 'Cédula'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
            onPressed: () async {
              try {
                await context.read<AdminProvider>().updateUser(user.idUsuario, {
                  'nombre': nombreCtrl.text,
                  'apellido': apellidoCtrl.text,
                  'telefono': telefonoCtrl.text,
                  'cedula': cedulaCtrl.text,
                });
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Usuario actualizado'), backgroundColor: Colors.green));
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.errorColor));
              }
            },
            child: const Text('Guardar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showCreateMechanicDialog(BuildContext context) {
    final nombreCtrl = TextEditingController();
    final apellidoCtrl = TextEditingController();
    final telefonoCtrl = TextEditingController();
    final cedulaCtrl = TextEditingController();
    final correoCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    final espCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.bg,
        title: const Text('Añadir Mecánico', style: TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTextField(nombreCtrl, 'Nombre'),
              const SizedBox(height: 12),
              _buildTextField(apellidoCtrl, 'Apellido'),
              const SizedBox(height: 12),
              _buildTextField(telefonoCtrl, 'Teléfono'),
              const SizedBox(height: 12),
              _buildTextField(cedulaCtrl, 'Cédula'),
              const SizedBox(height: 12),
              _buildTextField(correoCtrl, 'Correo', isEmail: true),
              const SizedBox(height: 12),
              _buildTextField(passCtrl, 'Contraseña', obscure: true),
              const SizedBox(height: 12),
              _buildTextField(espCtrl, 'Especialidad (Opcional)'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
            onPressed: () async {
              try {
                await context.read<AdminProvider>().createMechanic({
                  'nombre': nombreCtrl.text,
                  'apellido': apellidoCtrl.text,
                  'telefono': telefonoCtrl.text,
                  'cedula': cedulaCtrl.text,
                  'correo': correoCtrl.text,
                  'password': passCtrl.text,
                  'rol': 'Tecnico',
                  'especialidad': espCtrl.text.isNotEmpty ? espCtrl.text : null,
                });
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mecánico creado'), backgroundColor: Colors.green));
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.errorColor));
              }
            },
            child: const Text('Crear', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, {bool obscure = false, bool isEmail = false}) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: isEmail ? TextInputType.emailAddress : TextInputType.text,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        filled: true,
        fillColor: AppTheme.surfaceColor,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
      ),
    );
  }

  void _confirmDelete(BuildContext context, int id, String nombre) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        title: const Text('Eliminar Usuario', style: TextStyle(color: Colors.white)),
        content: Text(
          '¿Estás seguro de que deseas eliminar al usuario $nombre? Esta acción no se puede deshacer.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor),
            onPressed: () async {
              Navigator.pop(dialogContext);
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              try {
                await context.read<AdminProvider>().deleteUser(id);
                scaffoldMessenger.showSnackBar(
                  const SnackBar(content: Text('Usuario eliminado exitosamente'), backgroundColor: Colors.green),
                );
              } catch (e) {
                scaffoldMessenger.showSnackBar(
                  SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.errorColor),
                );
              }
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}
