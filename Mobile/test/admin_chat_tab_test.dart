import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/models/user_model.dart';
import 'package:mobile/providers/admin_provider.dart';
import 'package:mobile/providers/chat_provider.dart';
import 'package:mobile/screens/admin/widgets/admin_chat_tab.dart';
import 'package:mobile/widgets/unread_badge.dart';
import 'package:provider/provider.dart';

class FakeAdminProvider extends AdminProvider {
  FakeAdminProvider(this._users);

  final List<UserModel> _users;

  @override
  bool get isLoading => false;

  @override
  List<UserModel> get users => _users;

  @override
  Future<void> fetchUsers() async {}
}

UserModel buildUser({
  required int id,
  required String nombre,
  required String apellido,
  required String rol,
}) {
  return UserModel(
    idUsuario: id,
    nombre: nombre,
    apellido: apellido,
    telefono: '3000000000',
    cedula: '$id',
    correo: '$id@example.com',
    rol: rol,
    especialidad: null,
  );
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('filters admin users using backend role value', (tester) async {
    final provider = FakeAdminProvider([
      buildUser(id: 1, nombre: 'Ana', apellido: 'Admin', rol: 'Administrador'),
      buildUser(id: 2, nombre: 'Carlos', apellido: 'Cliente', rol: 'Cliente'),
    ]);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AdminProvider>.value(value: provider),
          ChangeNotifierProvider<ChatProvider>.value(value: ChatProvider()),
        ],
        child: const MaterialApp(home: Scaffold(body: AdminChatTab())),
      ),
    );
    await tester.pump();

    expect(find.text('Ana Admin'), findsNothing);
    expect(find.text('Carlos Cliente'), findsOneWidget);
  });

  testWidgets('shows unread badge for the matching chat user only', (
    tester,
  ) async {
    final adminProvider = FakeAdminProvider([
      buildUser(id: 2, nombre: 'Carlos', apellido: 'Cliente', rol: 'Cliente'),
      buildUser(id: 3, nombre: 'Marta', apellido: 'Mecanica', rol: 'Mecanico'),
    ]);
    final chatProvider = ChatProvider();
    chatProvider.handleSocketData(
      jsonEncode({
        'id': 101,
        'sender_id': 2,
        'receiver_id': 1,
        'content': 'Pendiente',
        'timestamp': '2026-07-17T15:10:00Z',
        'is_read': false,
        'status': 'sent',
      }),
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AdminProvider>.value(value: adminProvider),
          ChangeNotifierProvider<ChatProvider>.value(value: chatProvider),
        ],
        child: const MaterialApp(home: Scaffold(body: AdminChatTab())),
      ),
    );
    await tester.pump();

    expect(find.text('Carlos Cliente'), findsOneWidget);
    expect(find.text('Marta Mecanica'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(find.bySemanticsLabel('1 mensajes no leidos'), findsOneWidget);
  });

  testWidgets('uses minimal avatars and compact unread badges', (tester) async {
    final adminProvider = FakeAdminProvider([
      buildUser(id: 2, nombre: 'Carlos', apellido: 'Cliente', rol: 'Cliente'),
    ]);
    final chatProvider = ChatProvider();
    chatProvider.handleSocketData(
      jsonEncode({
        'id': 101,
        'sender_id': 2,
        'receiver_id': 1,
        'content': 'Pendiente',
        'timestamp': '2026-07-17T15:10:00Z',
        'is_read': false,
        'status': 'sent',
      }),
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AdminProvider>.value(value: adminProvider),
          ChangeNotifierProvider<ChatProvider>.value(value: chatProvider),
        ],
        child: const MaterialApp(home: Scaffold(body: AdminChatTab())),
      ),
    );
    await tester.pump();

    final avatar = tester.widget<Container>(
      find.ancestor(of: find.text('C').first, matching: find.byType(Container)),
    );
    final avatarDecoration = avatar.decoration! as BoxDecoration;
    final avatarBorder = avatarDecoration.border! as Border;

    expect(avatar.constraints!.minWidth, 38);
    expect(avatar.constraints!.minHeight, 38);
    expect(avatarDecoration.shape, BoxShape.circle);
    expect(avatarBorder.top.width, 0.8);

    final badge = tester.widget<UnreadBadge>(
      find.byWidgetPredicate(
        (widget) => widget is UnreadBadge && widget.count == 1,
      ),
    );

    expect(badge.compact, isTrue);
  });
}
