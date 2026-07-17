import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/providers/chat_provider.dart';
import 'package:mobile/widgets/dashboard_header.dart';
import 'package:provider/provider.dart';

class TestChatProvider extends ChatProvider {
  int connectCalls = 0;

  @override
  Future<void> connect() async {
    connectCalls += 1;
  }
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('DashboardHeader connects chat when mounted', (tester) async {
    final chatProvider = TestChatProvider();

    await tester.pumpWidget(
      ChangeNotifierProvider<ChatProvider>.value(
        value: chatProvider,
        child: const MaterialApp(
          home: Scaffold(
            body: DashboardHeader(role: 'Cliente', avatarText: 'NC'),
          ),
        ),
      ),
    );

    expect(chatProvider.connectCalls, 1);

    await tester.pump();

    expect(chatProvider.connectCalls, 1);
  });
}
