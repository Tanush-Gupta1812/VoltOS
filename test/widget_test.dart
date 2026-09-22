import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voltos/screens/bms_dashboard_screen.dart';

void main() {
  group('BMS Dashboard Screen Tests', () {
    testWidgets('Renders hero SOC percentage and initial active switches', (
      WidgetTester tester,
    ) async {
      final controller = BmsController(
        initialData: const BatteryData(
          socPercent: 78.0,
          voltage: 51.84,
          current: -12.4,
          chargingEnabled: true,
          dischargingEnabled: true,
          isConnected: true,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(home: BmsDashboardScreen(controller: controller)),
      );

      // Hero gauge
      expect(find.text('78%'), findsOneWidget);
      expect(find.text('DISCHARGING'), findsOneWidget);

      // Switches
      expect(find.text('CHARGE'), findsOneWidget);
      expect(find.text('DISCHARGE'), findsOneWidget);
      expect(find.text('ACTIVE • ON'), findsNWidgets(2));

      // Secondary Telemetry
      expect(find.text('51.84 V'), findsOneWidget);
      expect(find.text('-12.4 A'), findsOneWidget);
    });

    testWidgets('Tapping toggle opens safety confirmation dialog and does not toggle immediately', (
      WidgetTester tester,
    ) async {
      final controller = BmsController(
        initialData: const BatteryData(
          socPercent: 85.0,
          voltage: 52.1,
          current: 0.0,
          chargingEnabled: true,
          dischargingEnabled: true,
          isConnected: true,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(home: BmsDashboardScreen(controller: controller)),
      );

      // Verify initial state is chargingEnabled = true
      expect(controller.data.chargingEnabled, isTrue);

      // Tap on the Charge switch
      await tester.tap(find.text('CHARGE'));
      await tester.pumpAndSettle();

      // Verify safety confirmation dialog is shown
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Disable Charging?'), findsOneWidget);

      // Verify that the state has NOT toggled yet!
      expect(controller.data.chargingEnabled, isTrue);

      // Tap Cancel
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Verify dialog is dismissed and state remains unchanged
      expect(find.byType(AlertDialog), findsNothing);
      expect(controller.data.chargingEnabled, isTrue);

      // Now tap again and confirm
      await tester.tap(find.text('CHARGE'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Turn OFF Charge'));
      await tester.pumpAndSettle();

      // State is now toggled to false
      expect(controller.data.chargingEnabled, isFalse);
      expect(find.text('DISABLED • OFF'), findsOneWidget);
    });

    testWidgets('Discharge cut confirmation dialog contains safety consequences', (
      WidgetTester tester,
    ) async {
      final controller = BmsController(
        initialData: const BatteryData(
          socPercent: 50.0,
          voltage: 48.0,
          current: -10.0,
          chargingEnabled: false,
          dischargingEnabled: true,
          isConnected: true,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(home: BmsDashboardScreen(controller: controller)),
      );

      // Tap on DISCHARGE switch
      await tester.tap(find.text('DISCHARGE'));
      await tester.pumpAndSettle();

      // Check safety dialog text
      expect(find.text('Cut Power Output?'), findsOneWidget);
      expect(
        find.textContaining('CUT POWER to all connected loads'),
        findsOneWidget,
      );

      // Confirm cutting power
      await tester.tap(find.text('Cut Output Power'));
      await tester.pumpAndSettle();

      expect(controller.data.dischargingEnabled, isFalse);
    });

    testWidgets('Disconnected state disables switches and displays "Not connected"', (
      WidgetTester tester,
    ) async {
      final controller = BmsController(
        initialData: const BatteryData(
          socPercent: 78.0,
          voltage: 51.84,
          current: -12.4,
          chargingEnabled: true,
          dischargingEnabled: true,
          isConnected: false, // DISCONNECTED
        ),
      );

      await tester.pumpWidget(
        MaterialApp(home: BmsDashboardScreen(controller: controller)),
      );

      // Verify disconnected hero and switches
      expect(find.text('--%'), findsOneWidget);
      expect(find.text('OFFLINE'), findsOneWidget);
      expect(find.text('Not connected'), findsWidgets);
      expect(find.text('-- V'), findsOneWidget);
      expect(find.text('-- A'), findsOneWidget);

      // Tapping switch does nothing
      await tester.tap(find.text('CHARGE'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
    });
  });
}
