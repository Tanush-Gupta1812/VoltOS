import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voltos/screens/bms_dashboard_screen.dart';

void main() {
  group('BMS Dashboard Screen Tests', () {
    testWidgets('Renders hero SOC percentage, active device identity, and initial active switches', (
      WidgetTester tester,
    ) async {
      final controller = BmsController(
        initialData: const BatteryData(
          device: BmsDevice(
            id: 'A4:C1:38:7B:A1:04',
            name: 'VoltBMS-Main-Pack',
            model: '16S LiFePO4 • 48V 100Ah',
            rssi: -58,
            voltage: 51.84,
            socPercent: 78.0,
          ),
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

      // Active device card
      expect(find.text('VoltBMS-Main-Pack'), findsOneWidget);
      expect(find.text('-58 dBm'), findsOneWidget);
      expect(find.textContaining('A4:C1:38:7B:A1:04'), findsOneWidget);

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

    testWidgets('Device picker bottom sheet allows discovering and selecting a different BMS unit', (
      WidgetTester tester,
    ) async {
      final controller = BmsController();

      await tester.pumpWidget(
        MaterialApp(home: BmsDashboardScreen(controller: controller)),
      );

      // Tap on the active device card to open device switcher bottom sheet
      await tester.tap(find.text('VoltBMS-Main-Pack'));
      await tester.pumpAndSettle();

      // Bottom sheet is visible
      expect(find.text('Available BMS Units'), findsOneWidget);
      expect(find.text('VoltBMS-Aux-Pack'), findsOneWidget);
      expect(find.text('SolarStorage-BMS-02'), findsOneWidget);

      // Select the Aux Pack
      await tester.tap(find.text('VoltBMS-Aux-Pack'));
      await tester.pumpAndSettle();

      // Active device is now VoltBMS-Aux-Pack
      expect(controller.data.device?.name, 'VoltBMS-Aux-Pack');
      expect(find.text('VoltBMS-Aux-Pack'), findsOneWidget);
      expect(find.text('91%'), findsOneWidget); // Aux pack SOC is 91%
    });

    testWidgets('Tapping toggle opens safety confirmation dialog specifying target device', (
      WidgetTester tester,
    ) async {
      final controller = BmsController(
        initialData: const BatteryData(
          device: BmsDevice(
            id: 'A4:C1:38:7B:A1:04',
            name: 'VoltBMS-Main-Pack',
            model: '16S LiFePO4 • 48V 100Ah',
            rssi: -58,
            voltage: 52.1,
            socPercent: 85.0,
          ),
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

      // Verify safety confirmation dialog mentions target device name!
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Disable Charging?'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.textContaining('VoltBMS-Main-Pack'),
        ),
        findsOneWidget,
      );

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

      // Verify disconnected hero, active device card, and switches
      expect(find.text('--%'), findsOneWidget);
      expect(find.text('OFFLINE'), findsOneWidget);
      expect(find.text('No BMS Connected'), findsOneWidget);
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
