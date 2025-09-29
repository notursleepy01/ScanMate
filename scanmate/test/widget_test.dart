// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:scanmate/main.dart'; // This will be ScanMateApp

void main() {
  testWidgets('HomeScreen displays initial content', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    // We need to provide the necessary BLoCs if HomeScreen or its children depend on them directly.
    // For now, StorageService.initHive() is called in main.dart.
    // FileManagerBloc is provided within DocumentsScreen and HomeScreen.

    // It's good practice to initialize Hive for tests too if models are involved,
    // though this basic test might not hit Hive storage directly.
    // StorageService.initHive(); // Consider a test setup for Hive if needed.

    await tester.pumpWidget(const ScanMateApp());

    // Verify that HomeScreen shows "Documents" as the initial AppBar title.
    expect(find.text('Documents'), findsOneWidget);

    // Verify that the "Documents" tab label is present in the BottomNavigationBar/NavigationBar.
    expect(find.text('Documents'), findsWidgets); // It appears as title and tab label

    // Verify that one of the FABs (e.g., New Scan) is present initially.
    expect(find.byTooltip('New Scan'), findsOneWidget);
    expect(find.byTooltip('New Folder'), findsOneWidget);

  });
}
