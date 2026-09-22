import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voltos/screens/bms_dashboard_screen.dart';

void main() {
  group('BAT-BMS & Lossigy Live Bluetooth Tests', () {
    testWidgets('Dashboard Tab renders hero SOC, capacity Ah, cycles, and temperature probes', (
      WidgetTester tester,
    ) async {
      final controller = BmsController(
        initialData: BatteryData.demoPreset,
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
      final controller = BmsController(
        initialData: BatteryData.demoPreset,
      );

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
      final controller = BmsController(
        initialData: BatteryData.demoPreset,
      );

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

    testWidgets('Devices Tab shows empty state when no BLE devices nearby', (
      WidgetTester tester,
    ) async {
      final controller = BmsController(
        initialData: BatteryData.emptyDisconnected,
      );

      await tester.pumpWidget(
        MaterialApp(home: BmsDashboardScreen(controller: controller)),
      );

      // Switch to Devices tab
      await tester.tap(find.text('Devices'));
      await tester.pumpAndSettle();

      expect(find.text('Bluetooth LE Scanner'), findsOneWidget);
      expect(find.text('No Bluetooth Devices Detected'), findsOneWidget);
      expect(find.text('Load Demo Battery (Test UI)'), findsOneWidget);

      // Tap Load Demo Battery
      await tester.tap(find.text('Load Demo Battery (Test UI)'));
      await tester.pumpAndSettle();

      // Demo device is loaded
      expect(controller.data.device?.name, 'BAT-BMS-001');
      expect(find.text('BAT-BMS-001'), findsWidgets);
    });

    testWidgets('Tapping Charge/Discharge opens safety confirmation dialog specifying target device', (
      WidgetTester tester,
    ) async {
      final controller = BmsController(
        initialData: BatteryData.demoPreset,
      );

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
