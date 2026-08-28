import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:streakify/main.dart';
import 'package:streakify/providers/habit_provider.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  testWidgets('app loads with habit tracker title and add button', (
    tester,
  ) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => HabitProvider(),
        child: const MyApp(),
      ),
    );
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    expect(find.text('Racha actual: '), findsOneWidget);
    expect(find.byIcon(Icons.add_rounded), findsOneWidget);
  });

  testWidgets('creating a group does not throw a layout exception', (
    tester,
  ) async {
    final provider = HabitProvider();
    await tester.pumpWidget(
      ChangeNotifierProvider(create: (_) => provider, child: const MyApp()),
    );
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    await provider.addHabit('Hábito de prueba', Icons.star.codePoint);
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.edit_rounded));
    await tester.pump();
    await tester.tap(find.text('Nuevo Grupo'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Grupo de prueba');
    await tester.tap(find.text('Hábito de prueba'));
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Grupo de prueba'), findsOneWidget);
  });
}
