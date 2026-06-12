import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:knife_hit_game/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('smoke: app launches and shows home screen', (tester) async {
    app.main();
    await tester.pumpAndSettle(const Duration(seconds: 4));

    // Splash screen transitions to HomeScreen — check for KNIFE/HIT title
    expect(find.text('KNIFE'), findsOneWidget);
    expect(find.text('HIT'), findsOneWidget);
  });

  testWidgets('smoke: settings screen opens and closes', (tester) async {
    app.main();
    await tester.pumpAndSettle(const Duration(seconds: 4));

    // Tap the settings gear icon on the home screen
    final settingsIcon = find.byIcon(Icons.settings_rounded);
    expect(settingsIcon, findsOneWidget);
    await tester.tap(settingsIcon);
    await tester.pumpAndSettle();

    // Settings screen should show SETTINGS in the app bar
    expect(find.text('SETTINGS'), findsOneWidget);
    expect(find.text('DIFFICULTY'), findsOneWidget);

    // Navigate back
    final backButton = find.byType(BackButton);
    if (backButton.evaluate().isNotEmpty) {
      await tester.tap(backButton);
    } else {
      await tester.pageBack();
    }
    await tester.pumpAndSettle();

    // Back to home
    expect(find.text('KNIFE'), findsOneWidget);
  });

  testWidgets('smoke: tapping PLAY navigates to game screen', (tester) async {
    app.main();
    await tester.pumpAndSettle(const Duration(seconds: 4));

    final playButton = find.text('PLAY');
    expect(playButton, findsOneWidget);
    await tester.tap(playButton);
    // Give the game screen time to initialize (async difficulty load)
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // Game screen should be showing (no KNIFE/HIT title anymore)
    expect(find.text('KNIFE'), findsNothing);
    expect(find.text('HIT'), findsNothing);
  });
}
