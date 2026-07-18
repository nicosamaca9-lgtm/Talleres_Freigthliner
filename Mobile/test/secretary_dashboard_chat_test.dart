import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/providers/admin_provider.dart';
import 'package:mobile/providers/auth_provider.dart';
import 'package:mobile/providers/chat_provider.dart';
import 'package:mobile/screens/dashboard/secretary_dashboard_screen.dart';
import 'package:provider/provider.dart';

class FakeAuthProvider extends AuthProvider {
  @override
  String get initials => 'SS';

  @override
  int? get userId => 7;
}

class FakeAdminProvider extends AdminProvider {
  int fetchServiceOrdersCalls = 0;
  int fetchUsersCalls = 0;

  @override
  Future<void> fetchServiceOrders() async {
    fetchServiceOrdersCalls += 1;
  }

  @override
  Future<void> fetchUsers() async {
    fetchUsersCalls += 1;
  }
}

class FakeChatProvider extends ChatProvider {
  int connectCalls = 0;
  final List<dynamic> activeContacts = [];
  final List<dynamic> historyContacts = [];

  @override
  bool get isConnected => true;

  @override
  Future<void> connect() async {
    connectCalls += 1;
  }

  @override
  Future<void> setActiveContact(dynamic contactId) async {
    activeContacts.add(contactId);
  }

  @override
  Future<void> loadHistory(dynamic contactId) async {
    historyContacts.add(contactId);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const secureStorageChannel = MethodChannel(
    'plugins.it_nomads.com/flutter_secure_storage',
  );

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(secureStorageChannel, (call) async => null);
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(secureStorageChannel, null);
  });

  testWidgets(
    'secretary dashboard exposes chat as a fourth symmetric nav item',
    (tester) async {
      final authProvider = FakeAuthProvider();
      final adminProvider = FakeAdminProvider();
      final chatProvider = FakeChatProvider();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
            ChangeNotifierProvider<AdminProvider>.value(value: adminProvider),
            ChangeNotifierProvider<ChatProvider>.value(value: chatProvider),
          ],
          child: const MaterialApp(home: SecretaryDashboardScreen()),
        ),
      );
      await tester.pump();

      expect(find.text('Órdenes'), findsOneWidget);
      expect(find.text('Historial'), findsOneWidget);
      expect(find.text('Recibos'), findsOneWidget);
      expect(find.text('Chat'), findsOneWidget);

      await tester.tap(find.text('Chat'));
      await tester.pump(const Duration(milliseconds: 250));

      expect(find.text('Administrador'), findsOneWidget);
      expect(chatProvider.activeContacts, contains('admin'));
      expect(chatProvider.historyContacts, contains('admin'));
      expect(chatProvider.connectCalls, greaterThanOrEqualTo(2));
    },
  );
}
