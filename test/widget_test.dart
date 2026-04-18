// This is a basic Flutter widget test.

import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:chat_shell/main.dart';
import 'package:chat_shell/models/wallet.dart';

void main() {
  testWidgets('App starts smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => WalletProvider()),
        ],
        child: const GameBaaziApp(),
      ),
    );

    expect(find.text('GAMEBAAZI'), findsOneWidget);
  });
}
