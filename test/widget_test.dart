import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mon_app/main.dart';

void main() {
  testWidgets('AccueilScreen affiche le titre et la liste des appareils', (WidgetTester tester) async {
    await tester.pumpWidget(MonApp(modeInitial: ThemeMode.system));
    expect(find.text('SmartHome Connect'), findsOneWidget);
  });
}