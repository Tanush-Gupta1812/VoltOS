import 'dart:math' as math;
import 'package:flutter/material.dart';

// ============================================================================
// MODEL: BmsDevice
// ============================================================================

/// Identifies a specific physical BMS unit detected over Bluetooth LE.
class BmsDevice {
  /// Unique Hardware identifier (e.g. MAC address or BLE Peripheral UUID).
  final String id;

  /// Advertised or user-assigned device name.
  final String name;

  /// Pack chemistry / specification model description.
  final String model;

  /// Received Signal Strength Indication (dBm), e.g. -58 dBm.
  final int rssi;

  /// Current pack voltage preview.
  final double voltage;

  /// Current state of charge preview.
  final double socPercent;

  const BmsDevice({
    required this.id,
    required this.name,
    required this.model,
    required this.rssi,
    required this.voltage,
    required this.socPercent,
  });

  /// Human-readable signal quality rating.
  String get signalStrength {
    if (rssi >= -65) return 'Excellent';
    if (rssi >= -75) return 'Good';
    if (rssi >= -85) return 'Fair';
    return 'Weak';
  }
}

// ============================================================================
// MODEL: BatteryData
// ============================================================================

/// Immutable telemetry model representing live battery status for an active device.
class BatteryData {
  /// The physical device currently being monitored and controlled.
  final BmsDevice? device;

  /// State of charge percentage (0.0 to 100.0).
  final double socPercent;

  /// Pack voltage in Volts (e.g. 51.8 V).
  final double voltage;

  /// Pack current in Amperes (+ for charging, - for discharging, 0 for idle).
  final double current;

  /// State of the physical Charge MOSFET gate.
  final bool chargingEnabled;

  /// State of the physical Discharge MOSFET gate.
  final bool dischargingEnabled;

  /// Connection status to the physical BLE peripheral.
  final bool isConnected;

  const BatteryData({
    this.device,
    required this.socPercent,
    required this.voltage,
    required this.current,
    required this.chargingEnabled,
    required this.dischargingEnabled,
    required this.isConnected,
  });

  /// Instantaneous power in Watts (P = V * I).
  double get powerWatts => voltage * current;

  BatteryData copyWith({
    BmsDevice? device,
    double? socPercent,
    double? voltage,
    double? current,
    bool? chargingEnabled,
    bool? dischargingEnabled,
    bool? isConnected,
  }) {
    return BatteryData(
      device: device ?? this.device,
      socPercent: socPercent ?? this.socPercent,
      voltage: voltage ?? this.voltage,
      current: current ?? this.current,
      chargingEnabled: chargingEnabled ?? this.chargingEnabled,
      dischargingEnabled: dischargingEnabled ?? this.dischargingEnabled,
      isConnected: isConnected ?? this.isConnected,
    );
  }

  /// Initial default/mock data for preview and development.
  static const BatteryData mockDefault = BatteryData(
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
    current: -12.40, // Discharging at 12.4 A
    chargingEnabled: true,
    dischargingEnabled: true,
    isConnected: true,
  );
}

// ============================================================================
// CONTROLLER / STATE NOTIFIER: BmsController
// ============================================================================

/// State management controller using Flutter's native [ChangeNotifier].
///
/// ### Why ChangeNotifier?
/// 1. **Zero External Dependencies**: Works out-of-the-box in any Flutter project
///    without imposing Riverpod, Provider, or Bloc dependencies.
/// 2. **Clean Separation of Concerns**: Decouples the safety-critical MOSFET logic,
///    device discovery, and BLE hardware communication from widget presentation.
/// 3. **Interoperable**: Can be directly consumed via [ListenableBuilder], or
///    easily adapted to Riverpod (`ChangeNotifierProvider`), Provider, or Streams.
class BmsController extends ChangeNotifier {
  BatteryData _data;
  bool _isScanning = false;

  /// Sample mock list of nearby discovered BMS units.
  final List<BmsDevice> _availableDevices = const [
    BmsDevice(
      id: 'A4:C1:38:7B:A1:04',
      name: 'VoltBMS-Main-Pack',
      model: '16S LiFePO4 • 48V 100Ah',
      rssi: -58,
      voltage: 51.84,
      socPercent: 78.0,
    ),
    BmsDevice(
      id: 'B8:27:EB:12:34:56',
      name: 'VoltBMS-Aux-Pack',
      model: '16S LiFePO4 • 48V 50Ah',
      rssi: -71,
      voltage: 52.10,
      socPercent: 91.0,
    ),
    BmsDevice(
      id: 'DC:A6:32:89:FE:10',
      name: 'SolarStorage-BMS-02',
      model: '8S LFP • 24V 200Ah',
      rssi: -84,
      voltage: 26.40,
      socPercent: 45.0,
    ),
  ];

  BmsController({BatteryData? initialData})
      : _data = initialData ?? BatteryData.mockDefault;

  BatteryData get data => _data;
  bool get isScanning => _isScanning;
  List<BmsDevice> get availableDevices => _availableDevices;

  /// Updates live battery telemetry (e.g. from BLE notification stream).
  void updateTelemetry(BatteryData newData) {
    _data = newData;
    notifyListeners();
  }

  /// Toggles mock connection status for testing and visual validation.
  void toggleMockConnection() {
    _data = _data.copyWith(isConnected: !_data.isConnected);
    notifyListeners();
  }

  /// Connects to and switches control to the specified BMS device.
  Future<void> selectDevice(BmsDevice device) async {
    // =========================================================================
    // TODO: BLE Integration Point - Connect to Peripheral
    // Replace this mock switch with your actual BLE connection call:
    //
    // Example:
    // await bleAdapter.connect(device.id);
    // await bleAdapter.discoverServices();
    // =========================================================================

    _data = BatteryData(
      device: device,
      socPercent: device.socPercent,
      voltage: device.voltage,
      current: -5.0, // Mock initial current
      chargingEnabled: true,
      dischargingEnabled: true,
      isConnected: true,
    );
    notifyListeners();
  }

  /// Simulates or triggers a BLE scan for nearby BMS peripherals.
  Future<void> scanDevices() async {
    _isScanning = true;
    notifyListeners();

    // =========================================================================
    // TODO: BLE Integration Point - Peripheral Scanning
    // Replace this simulated delay with real BLE scan subscription:
    //
    // Example:
    // bleAdapter.startScan(withServices: [BMS_SERVICE_UUID]);
    // =========================================================================

    await Future.delayed(const Duration(milliseconds: 1200));
    _isScanning = false;
    notifyListeners();
  }

  /// Disconnects from the current active BMS.
  Future<void> disconnectCurrentDevice() async {
    // =========================================================================
    // TODO: BLE Integration Point - Disconnect Peripheral
    // await bleAdapter.disconnect(_data.device?.id);
    // =========================================================================

    _data = _data.copyWith(isConnected: false);
    notifyListeners();
  }

  /// Requests setting the physical Charge MOSFET state.
  ///
  /// This executes only AFTER the user confirms via the safety dialog.
  Future<void> setChargingEnabled(bool enable) async {
    if (!_data.isConnected) return;

    // =========================================================================
    // TODO: BLE Integration Point - Charge MOSFET Write Command
    // Replace this local state update with your actual BLE write call:
    //
    // Example:
    // await bleAdapter.writeCharacteristic(
    //   serviceUuid: '0000ffe0-0000-1000-8000-00805f9b34fb',
    //   characteristicUuid: '0000ffe1-0000-1000-8000-00805f9b34fb',
    //   data: [0xDD, 0x5A, 0x01, enable ? 0x01 : 0x00, 0x77],
    // );
    // =========================================================================

    _data = _data.copyWith(
      chargingEnabled: enable,
      // Adjust current if charging was shut down while receiving power:
      current: (!enable && _data.current > 0) ? 0.0 : _data.current,
    );
    notifyListeners();
  }

  /// Requests setting the physical Discharge MOSFET state.
  ///
  /// This executes only AFTER the user confirms via the safety dialog.
  Future<void> setDischargingEnabled(bool enable) async {
    if (!_data.isConnected) return;

    // =========================================================================
    // TODO: BLE Integration Point - Discharge MOSFET Write Command
    // Replace this local state update with your actual BLE write call:
    //
    // Example:
    // await bleAdapter.writeCharacteristic(
    //   serviceUuid: '0000ffe0-0000-1000-8000-00805f9b34fb',
    //   characteristicUuid: '0000ffe1-0000-1000-8000-00805f9b34fb',
    //   data: [0xDD, 0x5A, 0x02, enable ? 0x01 : 0x00, 0x77],
    // );
    // =========================================================================

    _data = _data.copyWith(
      dischargingEnabled: enable,
      // Cut load current to zero if discharge is turned off:
      current: (!enable && _data.current < 0) ? 0.0 : _data.current,
    );
    notifyListeners();
  }
}

// ============================================================================
// SCREEN WIDGET: BmsDashboardScreen
// ============================================================================

/// Minimal, safety-conscious main dashboard screen for the BMS Monitor app.
class BmsDashboardScreen extends StatefulWidget {
  /// Optional injected controller for testing or custom dependency injection.
  final BmsController? controller;

  const BmsDashboardScreen({super.key, this.controller});

  @override
  State<BmsDashboardScreen> createState() => _BmsDashboardScreenState();
}

class _BmsDashboardScreenState extends State<BmsDashboardScreen> {
  late final BmsController _controller;
  bool _isLocalController = false;

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      _controller = widget.controller!;
    } else {
      _controller = BmsController();
      _isLocalController = true;
    }
  }

  @override
  void dispose() {
    if (_isLocalController) {
      _controller.dispose();
    }
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // SAFETY CONFIRMATION DIALOG (CLEARLY IDENTIFIES TARGET DEVICE)
  // ---------------------------------------------------------------------------

  Future<void> _handleChargeToggle(BuildContext context, bool currentState) async {
    final deviceName = _controller.data.device?.name ?? 'BMS Device';
    final targetState = !currentState;

    final confirmed = await _showSafetyConfirmationDialog(
      context: context,
      title: targetState ? 'Enable Charging?' : 'Disable Charging?',
      warningMessage: targetState
          ? 'Target: "$deviceName"\n\nThis will close the Charge MOSFET and allow external charging current into the pack. Ensure charger voltage and limits are strictly compatible.'
          : 'Target: "$deviceName"\n\nThis will open the Charge MOSFET. The battery will immediately stop accepting power from chargers and solar inputs.',
      actionLabel: targetState ? 'Enable Charge' : 'Turn OFF Charge',
      isDestructive: !targetState,
    );

    if (confirmed == true && mounted) {
      await _controller.setChargingEnabled(targetState);
    }
  }

  Future<void> _handleDischargeToggle(BuildContext context, bool currentState) async {
    final deviceName = _controller.data.device?.name ?? 'BMS Device';
    final targetState = !currentState;

    final confirmed = await _showSafetyConfirmationDialog(
      context: context,
      title: targetState ? 'Enable Discharging?' : 'Cut Power Output?',
      warningMessage: targetState
          ? 'Target: "$deviceName"\n\nThis will close the Discharge MOSFET and energize all connected equipment, inverters, and loads.'
          : 'Target: "$deviceName"\n\nTurn OFF discharge? This will immediately open the MOSFET and CUT POWER to all connected loads and equipment.',
      actionLabel: targetState ? 'Enable Discharge' : 'Cut Output Power',
      isDestructive: !targetState,
    );

    if (confirmed == true && mounted) {
      await _controller.setDischargingEnabled(targetState);
    }
  }

  Future<bool?> _showSafetyConfirmationDialog({
    required BuildContext context,
    required String title,
    required String warningMessage,
    required String actionLabel,
    required bool isDestructive,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: isDestructive ? colorScheme.error.withValues(alpha: 0.4) : colorScheme.outlineVariant,
              width: 1.5,
            ),
          ),
          icon: Icon(
            isDestructive ? Icons.warning_amber_rounded : Icons.info_outline_rounded,
            color: isDestructive ? colorScheme.error : colorScheme.primary,
            size: 36,
          ),
          title: Text(
            title,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Text(
            warningMessage,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          actionsAlignment: MainAxisAlignment.spaceBetween,
          actionsPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                minimumSize: const Size(100, 48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(
                'Cancel',
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                minimumSize: const Size(130, 48),
                backgroundColor: isDestructive ? colorScheme.error : colorScheme.primary,
                foregroundColor: isDestructive ? colorScheme.onError : colorScheme.onPrimary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(
                actionLabel,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // DEVICE SELECTION BOTTOM SHEET
  // ---------------------------------------------------------------------------

  void _showDevicePickerBottomSheet(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (bottomSheetContext) {
        return ListenableBuilder(
          listenable: _controller,
          builder: (context, _) {
            final activeId = _controller.data.isConnected ? _controller.data.device?.id : null;

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Sheet Handle bar
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: colorScheme.outlineVariant,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Sheet Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Available BMS Units',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                'Select a physical battery to monitor and control',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton.filledTonal(
                          tooltip: 'Scan for Devices',
                          onPressed: _controller.isScanning ? null : () => _controller.scanDevices(),
                          icon: _controller.isScanning
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.refresh_rounded),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // List of Available Devices
                    ..._controller.availableDevices.map((dev) {
                      final isCurrent = dev.id == activeId;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Material(
                          color: isCurrent
                              ? colorScheme.primaryContainer.withValues(alpha: 0.35)
                              : colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: isCurrent
                                  ? colorScheme.primary
                                  : colorScheme.outlineVariant.withValues(alpha: 0.5),
                              width: isCurrent ? 2 : 1,
                            ),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            leading: CircleAvatar(
                              backgroundColor: isCurrent
                                  ? colorScheme.primary
                                  : colorScheme.surfaceContainerHighest,
                              foregroundColor: isCurrent
                                  ? colorScheme.onPrimary
                                  : colorScheme.onSurfaceVariant,
                              child: Icon(
                                isCurrent ? Icons.bluetooth_connected_rounded : Icons.bluetooth_rounded,
                                size: 20,
                              ),
                            ),
                            title: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    dev.name,
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                if (isCurrent)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: colorScheme.primary,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      'ACTIVE',
                                      style: TextStyle(
                                        color: colorScheme.onPrimary,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 2),
                                Text(
                                  '${dev.model} • MAC: ${dev.id}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontSize: 11,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${dev.socPercent.toInt()}% SOC • ${dev.voltage.toStringAsFixed(1)}V • Signal: ${dev.rssi} dBm (${dev.signalStrength})',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    fontSize: 11,
                                    color: isCurrent ? colorScheme.primary : colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            onTap: () {
                              _controller.selectDevice(dev);
                              Navigator.of(bottomSheetContext).pop();
                            },
                          ),
                        ),
                      );
                    }),

                    const SizedBox(height: 8),

                    // Disconnect Option
                    if (_controller.data.isConnected)
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                          foregroundColor: colorScheme.error,
                          side: BorderSide(color: colorScheme.error.withValues(alpha: 0.5)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () {
                          _controller.disconnectCurrentDevice();
                          Navigator.of(bottomSheetContext).pop();
                        },
                        icon: const Icon(Icons.link_off_rounded),
                        label: const Text('Disconnect Current Device'),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // BUILD METHOD & HIERARCHICAL LAYOUT
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final data = _controller.data;

        return Scaffold(
          backgroundColor: colorScheme.surface,
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: math.max(0, constraints.maxHeight - 32),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // --- 1. Top Header with Active Device Identity Card ---
                        _buildHeader(context, data),

                        const SizedBox(height: 12),

                        // --- 2. Active Target Device Identity Banner ---
                        _buildActiveDeviceCard(context, data),

                        const SizedBox(height: 16),

                        // --- 3. Primary Element: Hero Battery SOC Ring & Percentage ---
                        _buildHeroBatterySoc(context, data),

                        const SizedBox(height: 24),

                        // --- 4. Safety-Relevant MOSFET Controls (Charge / Discharge) ---
                        _buildMosfetSwitches(context, data, constraints.maxWidth),

                        const SizedBox(height: 24),

                        // --- 5. Visually Secondary Telemetry Row (Voltage, Current, Power) ---
                        _buildSecondaryTelemetry(context, data),

                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // HEADER
  // ---------------------------------------------------------------------------

  Widget _buildHeader(BuildContext context, BatteryData data) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isConnected = data.isConnected;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'BMS Monitor',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: 0.2,
                color: colorScheme.onSurface,
              ),
            ),
            Text(
              'VoltOS Hardware Controller',
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
        // Interactive connection badge (tap to toggle connection state for testing)
        InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _controller.toggleMockConnection(),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isConnected
                  ? colorScheme.primaryContainer.withValues(alpha: 0.3)
                  : colorScheme.errorContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isConnected
                    ? colorScheme.primary.withValues(alpha: 0.4)
                    : colorScheme.error.withValues(alpha: 0.4),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isConnected ? Colors.tealAccent.shade700 : colorScheme.error,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  isConnected ? 'BLE Connected' : 'Disconnected',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isConnected ? colorScheme.onSurface : colorScheme.error,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // ACTIVE DEVICE IDENTITY CARD
  // ---------------------------------------------------------------------------

  Widget _buildActiveDeviceCard(BuildContext context, BatteryData data) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isConnected = data.isConnected;
    final device = data.device;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showDevicePickerBottomSheet(context),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isConnected
                ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.4)
                : colorScheme.errorContainer.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isConnected
                  ? colorScheme.outlineVariant.withValues(alpha: 0.6)
                  : colorScheme.error.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isConnected
                      ? colorScheme.primary.withValues(alpha: 0.15)
                      : colorScheme.error.withValues(alpha: 0.15),
                ),
                child: Icon(
                  isConnected ? Icons.bluetooth_connected_rounded : Icons.bluetooth_disabled_rounded,
                  size: 20,
                  color: isConnected ? colorScheme.primary : colorScheme.error,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            isConnected ? (device?.name ?? 'Unknown BMS') : 'No BMS Connected',
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ),
                        if (isConnected && device != null) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${device.rssi} dBm',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isConnected
                          ? 'MAC: ${device?.id ?? "N/A"} • Tap to switch'
                          : 'Tap to scan and pair BMS hardware',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 11,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.swap_horiz_rounded,
                size: 20,
                color: colorScheme.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // HERO SOC PERCENTAGE RING
  // ---------------------------------------------------------------------------

  Widget _buildHeroBatterySoc(BuildContext context, BatteryData data) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isConnected = data.isConnected;

    // Determine state color
    final Color ringColor;
    if (!isConnected) {
      ringColor = colorScheme.outlineVariant;
    } else if (data.socPercent <= 20) {
      ringColor = colorScheme.error;
    } else if (data.current > 0.1) {
      ringColor = Colors.teal.shade400;
    } else {
      ringColor = colorScheme.primary;
    }

    // Determine sub-label
    final String stateLabel;
    final IconData stateIcon;
    if (!isConnected) {
      stateLabel = 'OFFLINE';
      stateIcon = Icons.cloud_off_rounded;
    } else if (data.current > 0.2) {
      stateLabel = 'CHARGING';
      stateIcon = Icons.bolt_rounded;
    } else if (data.current < -0.2) {
      stateLabel = 'DISCHARGING';
      stateIcon = Icons.arrow_downward_rounded;
    } else {
      stateLabel = 'STANDBY';
      stateIcon = Icons.pause_circle_outline_rounded;
    }

    final double socFill = isConnected ? (data.socPercent.clamp(0.0, 100.0) / 100.0) : 0.0;

    return Center(
      child: SizedBox(
        width: 230,
        height: 230,
        child: CustomPaint(
          painter: _BatteryProgressRingPainter(
            progress: socFill,
            trackColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
            progressColor: ringColor,
            strokeWidth: 16.0,
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Top Status Icon with Label
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      stateIcon,
                      size: 16,
                      color: isConnected ? ringColor : colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      stateLabel,
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                        color: isConnected ? ringColor : colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Big Bold Percentage Display
                Text(
                  isConnected ? '${data.socPercent.toInt()}%' : '--%',
                  style: theme.textTheme.displayLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 58,
                    letterSpacing: -1.5,
                    color: isConnected ? colorScheme.onSurface : colorScheme.onSurfaceVariant,
                  ),
                ),

                const SizedBox(height: 4),

                // Subtle Battery Level text
                Text(
                  isConnected ? 'State of Charge' : 'Not Connected',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SAFETY MOSFET SWITCH CONTROLS
  // ---------------------------------------------------------------------------

  Widget _buildMosfetSwitches(BuildContext context, BatteryData data, double availableWidth) {
    final isConnected = data.isConnected;
    final isNarrow = availableWidth < 340;

    final chargeSwitch = _SafetyToggleButton(
      title: 'CHARGE',
      subtitle: !isConnected
          ? 'Not connected'
          : (data.chargingEnabled ? 'ACTIVE • ON' : 'DISABLED • OFF'),
      isActive: data.chargingEnabled && isConnected,
      isDisabled: !isConnected,
      activeIcon: Icons.bolt_rounded,
      inactiveIcon: Icons.power_off_rounded,
      activeColor: Colors.teal.shade600,
      onTap: isConnected ? () => _handleChargeToggle(context, data.chargingEnabled) : null,
    );

    final dischargeSwitch = _SafetyToggleButton(
      title: 'DISCHARGE',
      subtitle: !isConnected
          ? 'Not connected'
          : (data.dischargingEnabled ? 'ACTIVE • ON' : 'DISABLED • OFF'),
      isActive: data.dischargingEnabled && isConnected,
      isDisabled: !isConnected,
      activeIcon: Icons.power_rounded,
      inactiveIcon: Icons.block_rounded,
      activeColor: Theme.of(context).colorScheme.primary,
      onTap: isConnected ? () => _handleDischargeToggle(context, data.dischargingEnabled) : null,
    );

    if (isNarrow) {
      return Column(
        children: [
          chargeSwitch,
          const SizedBox(height: 12),
          dischargeSwitch,
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: chargeSwitch),
        const SizedBox(width: 16),
        Expanded(child: dischargeSwitch),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // SECONDARY TELEMETRY SECTION
  // ---------------------------------------------------------------------------

  Widget _buildSecondaryTelemetry(BuildContext context, BatteryData data) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isConnected = data.isConnected;

    final voltageStr = isConnected ? '${data.voltage.toStringAsFixed(2)} V' : '-- V';
    final currentSign = data.current > 0 ? '+' : '';
    final currentStr = isConnected ? '$currentSign${data.current.toStringAsFixed(1)} A' : '-- A';
    final powerSign = data.powerWatts > 0 ? '+' : '';
    final powerStr = isConnected ? '$powerSign${data.powerWatts.abs().toStringAsFixed(0)} W' : '-- W';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildTelemetryMetric(
            context: context,
            label: 'VOLTAGE',
            value: voltageStr,
            icon: Icons.electric_meter_outlined,
          ),
          Container(
            height: 32,
            width: 1,
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
          _buildTelemetryMetric(
            context: context,
            label: 'CURRENT',
            value: currentStr,
            icon: Icons.swap_vert_rounded,
          ),
          Container(
            height: 32,
            width: 1,
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
          _buildTelemetryMetric(
            context: context,
            label: 'POWER',
            value: powerStr,
            icon: Icons.offline_bolt_outlined,
          ),
        ],
      ),
    );
  }

  Widget _buildTelemetryMetric({
    required BuildContext context,
    required String label,
    required String value,
    required IconData icon,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: colorScheme.onSurfaceVariant),
            const SizedBox(width: 4),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: 10,
                letterSpacing: 0.8,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
            color: colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// CUSTOM WIDGET: _SafetyToggleButton
// ============================================================================

/// Large, high-visibility safety button representing physical MOSFET gates.
///
/// Features:
/// - Minimum height: 68dp (exceeds 56dp requirement).
/// - Multi-sensory states: color + distinct icon + explicit status label + fill style.
/// - Outlined/muted style when OFF, filled/solid style when ON.
/// - Low-opacity and disabled pointer events when disconnected.
class _SafetyToggleButton extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isActive;
  final bool isDisabled;
  final IconData activeIcon;
  final IconData inactiveIcon;
  final Color activeColor;
  final VoidCallback? onTap;

  const _SafetyToggleButton({
    required this.title,
    required this.subtitle,
    required this.isActive,
    required this.isDisabled,
    required this.activeIcon,
    required this.inactiveIcon,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Disabled / Disconnected state
    if (isDisabled) {
      return Container(
        constraints: const BoxConstraints(minHeight: 68),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.4)),
        ),
        child: Opacity(
          opacity: 0.45,
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colorScheme.surfaceContainerHighest,
                ),
                child: Icon(Icons.bluetooth_disabled_rounded, size: 22, color: colorScheme.onSurfaceVariant),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Active (ON) vs Inactive (OFF) styling
    final backgroundColor = isActive
        ? activeColor
        : colorScheme.surfaceContainerHighest.withValues(alpha: 0.2);

    final borderColor = isActive
        ? activeColor.withValues(alpha: 0.9)
        : colorScheme.outlineVariant;

    final foregroundColor = isActive ? Colors.white : colorScheme.onSurface;
    final subtitleColor = isActive ? Colors.white.withValues(alpha: 0.85) : colorScheme.onSurfaceVariant;
    final iconData = isActive ? activeIcon : inactiveIcon;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          constraints: const BoxConstraints(minHeight: 68),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: borderColor,
              width: isActive ? 2 : 1.5,
            ),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: activeColor.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isActive
                      ? Colors.white.withValues(alpha: 0.2)
                      : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                ),
                child: Icon(
                  iconData,
                  size: 22,
                  color: foregroundColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: foregroundColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: subtitleColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// PAINTER: _BatteryProgressRingPainter
// ============================================================================

/// Custom painter rendering the circular battery percentage progress ring.
class _BatteryProgressRingPainter extends CustomPainter {
  final double progress; // 0.0 to 1.0
  final Color trackColor;
  final Color progressColor;
  final double strokeWidth;

  const _BatteryProgressRingPainter({
    required this.progress,
    required this.trackColor,
    required this.progressColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) - strokeWidth) / 2;

    // Background track ring
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    if (progress <= 0) return;

    // Active progress arc starting from top (-pi / 2)
    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    const startAngle = -math.pi / 2;
    final sweepAngle = 2 * math.pi * progress;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _BatteryProgressRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.progressColor != progressColor ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
