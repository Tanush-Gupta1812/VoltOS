import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voltos/screens/bms_dashboard_screen.dart';

void main() {
  group('BAT-BMS & Lossigy Replica Screen Tests', () {
    testWidgets('Dashboard Tab renders hero SOC, capacity Ah, cycles, and temperature probes', (
      WidgetTester tester,
    ) async {
      final controller = BmsController(
        initialData: const BatteryData(
          device: BmsDevice(
            id: 'A4:C1:38:7B:A1:04',
            name: 'BAT-BMS-001',
            model: '16S LiFePO4 • 48V 100Ah',
            rssi: -58,
            voltage: 51.84,
            socPercent: 78.0,
          ),
          socPercent: 78.0,
          voltage: 51.84,
          current: -12.4,
          nominalCapacityAh: 100.0,
          remainingCapacityAh: 78.0,
          cycleCount: 142,
          chargingEnabled: true,
          dischargingEnabled: true,
          isConnected: true,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(home: BmsDashboardScreen(controller: controller)),
      );

      // App Title and Device Card
      expect(find.text('BAT-BMS Pro'), findsOneWidget);
      expect(find.text('BAT-BMS-001'), findsOneWidget);
      expect(find.text('-58 dBm'), findsOneWidget);

      // Hero gauge
      expect(find.text('78%'), findsOneWidget);
      expect(find.text('DISCHARGING'), findsOneWidget);

      // Capacity & Cycles
      expect(find.text('78.0 Ah'), findsOneWidget);
      expect(find.text('100 Ah'), findsOneWidget);
      expect(find.text('142'), findsOneWidget);

      // MOSFET Switches
      expect(find.text('CHARGE'), findsOneWidget);
      expect(find.text('DISCHARGE'), findsOneWidget);

      // Thermal Probes
      expect(find.text('Thermal Probes (°C)'), findsOneWidget);
      expect(find.text('Cell T1'), findsOneWidget);
      expect(find.text('MOSFET'), findsOneWidget);
    });

    testWidgets('Cells Tab displays 16S voltage map, max cell, min cell, and delta V', (
      WidgetTester tester,
    ) async {
      final controller = BmsController();

      await tester.pumpWidget(
        MaterialApp(home: BmsDashboardScreen(controller: controller)),
      );

      // Switch to Cells tab
      await tester.tap(find.text('Cells'));
      await tester.pumpAndSettle();

      // Verify cell diagnostics header
      expect(find.text('MAX CELL'), findsOneWidget);
      expect(find.text('MIN CELL'), findsOneWidget);
      expect(find.text('DELTA \u0394V'), findsOneWidget);
      expect(find.text('16S Cell Voltage Map'), findsOneWidget);
      expect(find.text('Cell 1'), findsOneWidget);
      expect(find.text('Cell 16'), findsOneWidget);
    });

    testWidgets('Controls Tab displays MOSFET switches and Hardware Protection Alarms', (
      WidgetTester tester,
    ) async {
      final controller = BmsController();

      await tester.pumpWidget(
        MaterialApp(home: BmsDashboardScreen(controller: controller)),
      );

      // Switch to Controls tab
      await tester.tap(find.text('Controls'));
      await tester.pumpAndSettle();

      expect(find.text('MOSFET Switch Controls'), findsOneWidget);
      expect(find.text('Auto-Balance Cells'), findsOneWidget);
      expect(find.text('Hardware Protection Alarms'), findsOneWidget);
      expect(find.text('Cell Over-Voltage Protection (OVP)'), findsOneWidget);
      expect(find.text('Short Circuit Protection (SCP)'), findsOneWidget);
      expect(find.text('NORMAL'), findsWidgets);
    });

    testWidgets('Devices Tab allows scanning and selecting nearby BMS packs', (
      WidgetTester tester,
    ) async {
      final controller = BmsController();

      await tester.pumpWidget(
        MaterialApp(home: BmsDashboardScreen(controller: controller)),
      );

      // Switch to Devices tab
      await tester.tap(find.text('Devices'));
      await tester.pumpAndSettle();

      expect(find.text('Bluetooth LE Scanner'), findsOneWidget);
      expect(find.widgetWithText(ListTile, 'BAT-BMS-001'), findsOneWidget);
      expect(find.widgetWithText(ListTile, 'Lossigy-48V-Aux'), findsOneWidget);

      // Connect to Lossigy-48V-Aux
      await tester.tap(find.widgetWithText(FilledButton, 'Connect').first);
      await tester.pumpAndSettle();

      // Controller active device updated
      expect(controller.data.device?.name, 'Lossigy-48V-Aux');
      expect(controller.data.socPercent, 91.0);
    });

    testWidgets('Tapping Charge/Discharge opens safety confirmation dialog specifying target device', (
      WidgetTester tester,
    ) async {
      final controller = BmsController();

      await tester.pumpWidget(
        MaterialApp(home: BmsDashboardScreen(controller: controller)),
      );

      // Tap Charge switch
      await tester.tap(find.text('CHARGE'));
      await tester.pumpAndSettle();

      // Check dialog
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Disable Charging?'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.textContaining('BAT-BMS-001'),
        ),
        findsOneWidget,
      );

      // State is preserved until confirmed
      expect(controller.data.chargingEnabled, isTrue);

      await tester.tap(find.text('Turn OFF Charge'));
      await tester.pumpAndSettle();

      expect(controller.data.chargingEnabled, isFalse);
    });
  });
}
