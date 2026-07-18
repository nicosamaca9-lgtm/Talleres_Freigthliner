import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/models/message_model.dart';
import 'package:mobile/models/message_status.dart';
import 'package:mobile/screens/chat/widgets/chat_message_bubble.dart';

MessageModel message({
  required int id,
  required int senderId,
  String content = 'Mensaje de prueba',
  bool isRead = false,
  String? deliveredAt,
  String? readAt,
  String? apiStatus,
}) {
  return MessageModel(
    id: id,
    senderId: senderId,
    receiverId: 2,
    content: content,
    timestamp: '2026-07-17T14:35:00',
    isRead: isRead,
    deliveredAt: deliveredAt,
    readAt: readAt,
    apiStatus: apiStatus,
  );
}

void main() {
  testWidgets('own messages show status checks next to the time', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChatMessageBubble(
            message: message(id: 1, senderId: 1, isRead: true),
            isMe: true,
          ),
        ),
      ),
    );

    expect(find.text('14:35'), findsOneWidget);
    expect(find.bySemanticsLabel('Mensaje leido'), findsOneWidget);
  });

  testWidgets('messages from the other participant never show status checks', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChatMessageBubble(
            message: message(id: 1, senderId: 2, isRead: true),
            isMe: false,
          ),
        ),
      ),
    );

    expect(find.text('14:35'), findsOneWidget);
    expect(find.bySemanticsLabel('Mensaje leido'), findsNothing);
    expect(find.bySemanticsLabel('Mensaje enviado'), findsNothing);
    expect(find.bySemanticsLabel('Mensaje entregado'), findsNothing);
  });

  testWidgets('short messages use a compact bubble width', (tester) async {
    tester.view.physicalSize = const Size(480, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChatMessageBubble(
            message: message(id: 1, senderId: 1, content: 'Ok'),
            isMe: true,
          ),
        ),
      ),
    );

    final bubbleFinder = find.ancestor(
      of: find.text('Ok'),
      matching: find.byType(Container),
    );

    expect(tester.getSize(bubbleFinder.last).width, lessThan(170));
  });

  testWidgets('message status is derived from real delivery/read data', (
    tester,
  ) async {
    expect(message(id: 1, senderId: 1).status, MessageStatus.sent);
    expect(
      message(id: 1, senderId: 1, deliveredAt: '2026-07-17T14:36:00Z').status,
      MessageStatus.delivered,
    );
    expect(
      message(id: 1, senderId: 1, readAt: '2026-07-17T14:37:00Z').status,
      MessageStatus.read,
    );
    expect(
      message(id: 1, senderId: 1, apiStatus: 'read').status,
      MessageStatus.read,
    );
  });
}
