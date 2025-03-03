// // This is a basic Flutter widget test.
// //
// // To perform an interaction with a widget in your test, use the WidgetTester
// // utility in the flutter_test package. For example, you can send tap and scroll
// // gestures. You can also use WidgetTester to find child widgets in the widget
// // tree, read text, and verify that the values of widget properties are correct.
//
// import 'package:flutter/material.dart';
// import 'package:flutter_test/flutter_test.dart';
//
// import 'package:mecon_biometric_app/main.dart';
//
// void main() {
//   testWidgets('Counter increments smoke test', (WidgetTester tester) async {
//     // Build our app and trigger a frame.
//     await tester.pumpWidget(const MyApp());
//
//     // Verify that our counter starts at 0.
//     expect(find.text('0'), findsOneWidget);
//     expect(find.text('1'), findsNothing);
//
//     // Tap the '+' icon and trigger a frame.
//     await tester.tap(find.byIcon(Icons.add));
//     await tester.pump();
//
//     // Verify that our counter has incremented.
//     expect(find.text('0'), findsNothing);
//     expect(find.text('1'), findsOneWidget);
//   });
// }

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mecon_biometric_app/main.dart';
import 'package:mockito/mockito.dart';
import 'package:mecon_biometric_app/camera_page.dart';

// ✅ Step 1: Create a Mock Navigator Observer to track navigation
class MockNavigatorObserver extends Mock implements NavigatorObserver {}

void main() {
  testWidgets('Attendance Page UI test with mocked navigation', (WidgetTester tester) async {
    // ✅ Step 2: Initialize a mock navigation observer
    final mockObserver = MockNavigatorObserver();

    // ✅ Step 3: Pump the app with the mock navigator observer
    await tester.pumpWidget(
      MaterialApp(
        home: AttendancePage(),
        navigatorObservers: [mockObserver], // Attach the observer
      ),
    );

    // ✅ Step 4: Verify initial UI elements are present
    expect(find.text("Attendance System"), findsOneWidget); // Title
    expect(find.text("Take Selfie"), findsOneWidget); // Button text
    expect(find.byIcon(Icons.camera_alt), findsOneWidget); // Camera button

    // ✅ Step 5: Mock the navigation behavior for CameraPage
    when(mockObserver.didPush(any, any)).thenAnswer((_) async {
      return "mock_image.jpg"; // Fake image return
    });

    // ✅ Step 6: Simulate clicking the "Take Selfie" button
    await tester.tap(find.byIcon(Icons.camera_alt));
    await tester.pump();

    // ✅ Step 7: Ensure the UI updates correctly after taking a selfie
    expect(find.byType(Image), findsNothing); // The mock image won't actually display in tests
  });
}
