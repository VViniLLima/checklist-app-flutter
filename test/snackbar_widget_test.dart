import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('SnackBar is dismissed after duration when shown with removeCurrentSnackBar()', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: ElevatedButton(
              onPressed: () {
                final messenger = ScaffoldMessenger.of(context);
                messenger.removeCurrentSnackBar();
                messenger.showSnackBar(
                  SnackBar(
                    content: const Text('Item removido'),
                    duration: const Duration(seconds: 5),
                    action: SnackBarAction(label: 'Desfazer', onPressed: () {}),
                  ),
                );
              },
              child: const Text('Show'),
            ),
          ),
        ),
      ),
    ));

    // Tap the button to show the SnackBar
    await tester.tap(find.text('Show'));
    await tester.pump();

    // SnackBar should be visible immediately
    expect(find.text('Item removido'), findsOneWidget);

    // Advance time by 5 seconds to allow SnackBar to dismiss
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    // SnackBar should no longer be in the tree
    expect(find.text('Item removido'), findsNothing);
  });
}
