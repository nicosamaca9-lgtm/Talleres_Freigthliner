import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/admin_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/user_model.dart';
import '../../../models/user_role.dart';
import 'package:flutter/services.dart';

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
                        style: TextStyle(color: AppTheme.textColor(context)),
                        decoration: InputDecoration(
                          hintText: 'Buscar por nombre, correo o cédula...',
                          hintStyle: TextStyle(
                            color: AppTheme.textMutedColor(context),
                          ),
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
                        onChanged: (val) {
                          setState(() {
                            _searchQuery = val;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.person_add, color: Colors.black),
                      label: const Text(
                        'Añadir Personal',
                        style: TextStyle(color: Colors.black),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                      ),
                      onPressed: () => _showCreateStaffDialog(context),
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
                    final isMechanic = user.userRole == UserRole.mechanic;
                    final isAdmin = user.userRole == UserRole.admin;
                    final isSecretary = user.userRole == UserRole.secretary;

                    return Card(
                      color: AppTheme.cardColor(context),
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isAdmin
                              ? Colors.red
                              : isMechanic
                              ? Colors.orange
                              : isSecretary
                              ? Colors.purple
                              : AppTheme.primaryColor,
                          child: Icon(
                            isAdmin
                                ? Icons.admin_panel_settings
                                : isMechanic
                                ? Icons.build
                                : isSecretary
                                ? Icons.badge
                                : Icons.person,
                            color: Colors.white,
                          ),
                        ),
                        title: Text(
                          user.nombreCompleto,
                          style: TextStyle(
                            color: AppTheme.textColor(context),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          '${user.correoElectronico}\nC.C: ${user.cedula} | Rol: ${user.rol}',
                          style: TextStyle(
                            color: AppTheme.textMutedColor(context),
                          ),
                        ),
                        isThreeLine: true,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.edit,
                                color: Colors.blueAccent,
                              ),
                              onPressed: () =>
                                  _showEditUserDialog(context, user),
                            ),
                            if (!isAdmin)
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: AppTheme.errorColor,
                                ),
                                onPressed: () => _confirmDelete(
                                  context,
                                  user.idUsuario,
                                  user.nombreCompleto,
                                ),
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
    final nombreCtrl = TextEditingController(
      text: user.nombreCompleto.split(' ').first,
    );
    final apellidoCtrl = TextEditingController(
      text: user.nombreCompleto.split(' ').skip(1).join(' '),
    );
    final telefonoCtrl = TextEditingController(text: user.telefono);
    final cedulaCtrl = TextEditingController(text: user.cedula);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.cardColor(context),
        title: Text(
          'Editar Usuario',
          style: TextStyle(color: AppTheme.textColor(context)),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTextField(context, nombreCtrl, 'Nombre'),
              const SizedBox(height: 12),
              _buildTextField(context, apellidoCtrl, 'Apellido'),
              const SizedBox(height: 12),
              _buildTextField(
                context,
                telefonoCtrl,
                'Teléfono',
                isNumeric: true,
                maxLength: 10,
              ),
              const SizedBox(height: 12),
              _buildTextField(context, cedulaCtrl, 'Cédula', isNumeric: true),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Cancelar',
              style: TextStyle(color: AppTheme.textMutedColor(context)),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
            ),
            onPressed: () async {
              final adminProvider = context.read<AdminProvider>();
              final navigator = Navigator.of(dialogContext);
              final scaffoldMessenger = ScaffoldMessenger.of(context);

              if (telefonoCtrl.text.length != 10) {
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text(
                      'El teléfono debe tener exactamente 10 dígitos',
                    ),
                    backgroundColor: AppTheme.errorColor,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                return;
              }
              try {
                await adminProvider.updateUser(user.idUsuario, {
                  'nombre': nombreCtrl.text,
                  'apellido': apellidoCtrl.text,
                  'telefono': telefonoCtrl.text,
                  'cedula': cedulaCtrl.text,
                });
                navigator.pop();
                scaffoldMessenger.showSnackBar(
                  const SnackBar(
                    content: Text('Usuario actualizado'),
                    backgroundColor: Colors.green,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              } catch (e) {
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text('Error: $e'),
                    backgroundColor: AppTheme.errorColor,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('Guardar', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  void _showCreateStaffDialog(BuildContext context) {
    final nombreCtrl = TextEditingController();
    final apellidoCtrl = TextEditingController();
    final telefonoCtrl = TextEditingController();
    final cedulaCtrl = TextEditingController();
    final correoCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    final espCtrl = TextEditingController();
    String selectedRole = 'Tecnico';

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setStateSB) {
          return AlertDialog(
            backgroundColor: AppTheme.cardColor(context),
            title: Text(
              'Añadir Personal',
              style: TextStyle(color: AppTheme.textColor(context)),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildTextField(context, nombreCtrl, 'Nombre'),
                  const SizedBox(height: 12),
                  _buildTextField(context, apellidoCtrl, 'Apellido'),
                  const SizedBox(height: 12),
                  _buildTextField(
                    context,
                    telefonoCtrl,
                    'Teléfono',
                    isNumeric: true,
                    maxLength: 10,
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    context,
                    cedulaCtrl,
                    'Cédula',
                    isNumeric: true,
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(context, correoCtrl, 'Correo', isEmail: true),
                  const SizedBox(height: 12),
                  _buildTextField(
                    context,
                    passCtrl,
                    'Contraseña',
                    obscure: true,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: selectedRole,
                    dropdownColor: AppTheme.cardColor(context),
                    style: TextStyle(color: AppTheme.textColor(context)),
                    decoration: InputDecoration(
                      labelText: 'Rol',
                      labelStyle: TextStyle(
                        color: AppTheme.textMutedColor(context),
                      ),
                      filled: true,
                      fillColor: AppTheme.inputColor(context),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'Tecnico',
                        child: Text('Técnico'),
                      ),
                      DropdownMenuItem(
                        value: 'Secretario',
                        child: Text('Secretario'),
                      ),
                    ],
                    onChanged: (val) {
                      setStateSB(() {
                        selectedRole = val!;
                      });
                    },
                  ),
                  if (selectedRole == 'Tecnico') ...[
                    const SizedBox(height: 12),
                    _buildTextField(
                      context,
                      espCtrl,
                      'Especialidad (Opcional)',
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(
                  'Cancelar',
                  style: TextStyle(color: AppTheme.textMutedColor(context)),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                ),
                onPressed: () async {
                  final adminProvider = context.read<AdminProvider>();
                  final navigator = Navigator.of(dialogContext);
                  final scaffoldMessenger = ScaffoldMessenger.of(context);

                  if (telefonoCtrl.text.length != 10) {
                    scaffoldMessenger.showSnackBar(
                      SnackBar(
                        content: Text(
                          'El teléfono debe tener exactamente 10 dígitos',
                        ),
                        backgroundColor: AppTheme.errorColor,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    return;
                  }
                  try {
                    await adminProvider.createMechanic({
                      'nombre': nombreCtrl.text,
                      'apellido': apellidoCtrl.text,
                      'telefono': telefonoCtrl.text,
                      'cedula': cedulaCtrl.text,
                      'correo': correoCtrl.text,
                      'password': passCtrl.text,
                      'rol': selectedRole,
                      'especialidad':
                          selectedRole == 'Tecnico' && espCtrl.text.isNotEmpty
                          ? espCtrl.text
                          : null,
                    });
                    navigator.pop();
                    scaffoldMessenger.showSnackBar(
                      SnackBar(
                        content: Text('$selectedRole creado exitosamente'),
                        backgroundColor: Colors.green,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  } catch (e) {
                    scaffoldMessenger.showSnackBar(
                      SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: AppTheme.errorColor,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
                child: const Text(
                  'Crear',
                  style: TextStyle(color: Colors.black),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTextField(
    BuildContext context,
    TextEditingController controller,
    String label, {
    bool obscure = false,
    bool isEmail = false,
    bool isNumeric = false,
    int? maxLength,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      maxLength: maxLength,
      keyboardType: isNumeric
          ? TextInputType.number
          : (isEmail ? TextInputType.emailAddress : TextInputType.text),
      inputFormatters: isNumeric
          ? [FilteringTextInputFormatter.digitsOnly]
          : null,
      style: TextStyle(color: AppTheme.textColor(context)),
      decoration: InputDecoration(
        labelText: label,
        counterText: '',
        labelStyle: TextStyle(color: AppTheme.textMutedColor(context)),
        filled: true,
        fillColor: AppTheme.inputColor(context),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, int id, String nombre) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.cardColor(context),
        title: Text(
          'Eliminar Usuario',
          style: TextStyle(color: AppTheme.textColor(context)),
        ),
        content: Text(
          '¿Estás seguro de que deseas eliminar al usuario $nombre? Esta acción no se puede deshacer.',
          style: TextStyle(color: AppTheme.textMutedColor(context)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Cancelar',
              style: TextStyle(color: AppTheme.textMutedColor(context)),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            onPressed: () async {
              Navigator.pop(dialogContext);
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              try {
                await context.read<AdminProvider>().deleteUser(id);
                scaffoldMessenger.showSnackBar(
                  const SnackBar(
                    content: Text('Usuario eliminado exitosamente'),
                    backgroundColor: Colors.green,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              } catch (e) {
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text('Error: $e'),
                    backgroundColor: AppTheme.errorColor,
                  ),
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
