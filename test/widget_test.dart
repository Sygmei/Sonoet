import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sonoet/src/app.dart';

void main() {
  testWidgets('Sonoet practice screen smoke test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const ProviderScope(child: SonoetApp()));

    expect(find.text('Sonoet'), findsOneWidget);
    expect(find.byIcon(Icons.mic_rounded), findsOneWidget);
  });
}
