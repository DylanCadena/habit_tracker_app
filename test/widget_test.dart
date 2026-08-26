import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:habit_app/main.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  testWidgets('app loads with habit tracker title and add button', (tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Hábitos Diarios'), findsOneWidget);
    expect(find.byIcon(Icons.add), findsOneWidget);
  });
}
