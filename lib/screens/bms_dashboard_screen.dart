import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

// ============================================================================
// MODEL: BmsDevice
// ============================================================================

/// Identifies a physical BMS or BLE peripheral detected over Bluetooth LE.
class BmsDevice {
  final String id; // MAC address or UUID
  final String name;
  final String model;
  final int rssi; // Signal dBm
  final double voltage;
  final double socPercent;
  final BluetoothDevice? rawDevice; // Physical BLE handle

  const BmsDevice({
    required this.id,
    required this.name,
    required this.model,
    required this.rssi,
    required this.voltage,
    required this.socPercent,
    this.rawDevice,
  });

  String get signalStrength {
    if (rssi >= -65) return 'Excellent';
    if (rssi >= -75) return 'Good';
    if (rssi >= -85) return 'Fair';
    return 'Weak';
  }
}

// ============================================================================
// MODEL: BatteryProtectionStatus
// ============================================================================

class BatteryProtectionStatus {
  final bool overVoltage;
  final bool underVoltage;
  final bool chargeOverCurrent;
  final bool dischargeOverCurrent;
  final bool overTemperature;
  final bool lowTemperature;
  final bool shortCircuit;

  const BatteryProtectionStatus({
    this.overVoltage = false,
    this.underVoltage = false,
    this.chargeOverCurrent = false,
    this.dischargeOverCurrent = false,
    this.overTemperature = false,
    this.lowTemperature = false,
    this.shortCircuit = false,
  });

  bool get hasAnyFault =>
      overVoltage ||
      underVoltage ||
      chargeOverCurrent ||
      dischargeOverCurrent ||
      overTemperature ||
      lowTemperature ||
      shortCircuit;
}

// ============================================================================
// MODEL: BatteryData
// ============================================================================

class BatteryData {
  final BmsDevice? device;
  final double socPercent;
  final double voltage;
  final double current;
  final double nominalCapacityAh;
  final double remainingCapacityAh;
  final int cycleCount;
  final double cellTemp1;
  final double cellTemp2;
  final double mosTemp;
  final double ambientTemp;
  final bool chargingEnabled;
  final bool dischargingEnabled;
  final bool balanceEnabled;
  final bool isConnected;
  final List<double> cellVoltages;
  final BatteryProtectionStatus protection;

  const BatteryData({
    this.device,
    required this.socPercent,
    required this.voltage,
    required this.current,
    this.nominalCapacityAh = 100.0,
    this.remainingCapacityAh = 78.0,
    this.cycleCount = 142,
    this.cellTemp1 = 27.4,
    this.cellTemp2 = 28.1,
    this.mosTemp = 32.5,
    this.ambientTemp = 25.8,
    required this.chargingEnabled,
    required this.dischargingEnabled,
    this.balanceEnabled = true,
    required this.isConnected,
    this.cellVoltages = const [
      3.241, 3.238, 3.240, 3.242, 3.239, 3.241, 3.237, 3.240,
      3.238, 3.241, 3.230, 3.240, 3.239, 3.242, 3.238, 3.241,
    ],
    this.protection = const BatteryProtectionStatus(),
  });

  double get powerWatts => voltage * current;

  double get maxCellVoltage =>
      cellVoltages.isNotEmpty ? cellVoltages.reduce(math.max) : 0.0;

  double get minCellVoltage =>
      cellVoltages.isNotEmpty ? cellVoltages.reduce(math.min) : 0.0;

  double get cellDeltaVoltage => maxCellVoltage - minCellVoltage;

  int get maxCellIndex => cellVoltages.indexOf(maxCellVoltage) + 1;
  int get minCellIndex => cellVoltages.indexOf(minCellVoltage) + 1;

  BatteryData copyWith({
    BmsDevice? device,
    double? socPercent,
    double? voltage,
    double? current,
    double? nominalCapacityAh,
    double? remainingCapacityAh,
    int? cycleCount,
    double? cellTemp1,
    double? cellTemp2,
    double? mosTemp,
    double? ambientTemp,
    bool? chargingEnabled,
    bool? dischargingEnabled,
    bool? balanceEnabled,
    bool? isConnected,
    List<double>? cellVoltages,
    BatteryProtectionStatus? protection,
  }) {
    return BatteryData(
      device: device ?? this.device,
      socPercent: socPercent ?? this.socPercent,
      voltage: voltage ?? this.voltage,
      current: current ?? this.current,
      nominalCapacityAh: nominalCapacityAh ?? this.nominalCapacityAh,
      remainingCapacityAh: remainingCapacityAh ?? this.remainingCapacityAh,
      cycleCount: cycleCount ?? this.cycleCount,
      cellTemp1: cellTemp1 ?? this.cellTemp1,
      cellTemp2: cellTemp2 ?? this.cellTemp2,
      mosTemp: mosTemp ?? this.mosTemp,
      ambientTemp: ambientTemp ?? this.ambientTemp,
      chargingEnabled: chargingEnabled ?? this.chargingEnabled,
      dischargingEnabled: dischargingEnabled ?? this.dischargingEnabled,
      balanceEnabled: balanceEnabled ?? this.balanceEnabled,
      isConnected: isConnected ?? this.isConnected,
      cellVoltages: cellVoltages ?? this.cellVoltages,
      protection: protection ?? this.protection,
    );
  }

  static const BatteryData emptyDisconnected = BatteryData(
    device: null,
    socPercent: 0.0,
    voltage: 0.0,
    current: 0.0,
    nominalCapacityAh: 100.0,
    remainingCapacityAh: 0.0,
    cycleCount: 0,
    cellTemp1: 0.0,
    cellTemp2: 0.0,
    mosTemp: 0.0,
    ambientTemp: 0.0,
    chargingEnabled: false,
    dischargingEnabled: false,
    balanceEnabled: false,
    isConnected: false,
    cellVoltages: [],
  );

  static const BatteryData demoPreset = BatteryData(
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
    current: -12.40,
    nominalCapacityAh: 100.0,
    remainingCapacityAh: 78.0,
    cycleCount: 142,
    cellTemp1: 27.4,
    cellTemp2: 28.1,
    mosTemp: 32.5,
    ambientTemp: 25.8,
    chargingEnabled: true,
    dischargingEnabled: true,
    balanceEnabled: true,
    isConnected: true,
  );
}

// ============================================================================
// CONTROLLER: BmsController (LIVE BLUETOOTH HARDWARE SCANNER)
// ============================================================================

class BmsController extends ChangeNotifier {
  BatteryData _data;
  bool _isScanning = false;
  String? _statusMessage;
  final List<BmsDevice> _availableDevices = [];
  StreamSubscription<List<ScanResult>>? _scanSub;

  BmsController({BatteryData? initialData})
      : _data = initialData ?? BatteryData.emptyDisconnected {
    // If an initial device was provided, keep it; otherwise start clean
  }

  BatteryData get data => _data;
  bool get isScanning => _isScanning;
  String? get statusMessage => _statusMessage;
  List<BmsDevice> get availableDevices => List.unmodifiable(_availableDevices);

  @override
  void dispose() {
    _scanSub?.cancel();
    super.dispose();
  }

  void loadDemoPreset() {
    _data = BatteryData.demoPreset;
    if (!_availableDevices.any((d) => d.id == BatteryData.demoPreset.device?.id)) {
      _availableDevices.insert(0, BatteryData.demoPreset.device!);
    }
    _statusMessage = 'Loaded Demo Battery';
    notifyListeners();
  }

  void toggleMockConnection() {
    _data = _data.copyWith(isConnected: !_data.isConnected);
    notifyListeners();
  }

  /// Initiates live Bluetooth LE scanning using the phone's hardware antenna.
  Future<void> scanDevices() async {
    _isScanning = true;
    _statusMessage = 'Scanning Bluetooth LE airwaves...';
    _availableDevices.clear();
    notifyListeners();

    try {
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        // Request Bluetooth adapter turn-on if off
        final adapterState = await FlutterBluePlus.adapterState.first;
        if (adapterState != BluetoothAdapterState.on) {
          try {
            await FlutterBluePlus.turnOn();
          } catch (_) {}
        }
      }

      await _scanSub?.cancel();

      _scanSub = FlutterBluePlus.scanResults.listen((results) {
        for (final r in results) {
          final advName = r.advertisementData.advName.trim();
          final platName = r.device.platformName.trim();
          final macStr = r.device.remoteId.str;

          final displayName = advName.isNotEmpty
              ? advName
              : (platName.isNotEmpty
                  ? platName
                  : 'BLE Device (${macStr.length > 8 ? macStr.substring(0, 8) : macStr})');

          final device = BmsDevice(
            id: macStr,
            name: displayName,
            model: 'BLE Peripheral • RSSI ${r.rssi} dBm',
            rssi: r.rssi,
            voltage: 0.0,
            socPercent: 0.0,
            rawDevice: r.device,
          );

          final idx = _availableDevices.indexWhere((d) => d.id == device.id);
          if (idx >= 0) {
            _availableDevices[idx] = device;
          } else {
            _availableDevices.add(device);
          }
          notifyListeners();
        }
      });

      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 8));
      await FlutterBluePlus.isScanning.where((val) => val == false).first;
      _statusMessage = _availableDevices.isEmpty
          ? 'No BLE devices found nearby'
          : 'Found ${_availableDevices.length} BLE devices';
    } catch (e) {
      debugPrint('BLE Scan error: $e');
      _statusMessage = 'BLE scan: $e';
    } finally {
      _isScanning = false;
      notifyListeners();
    }
  }

  /// Connects to a selected physical BLE device.
  Future<void> selectDevice(BmsDevice device) async {
    _statusMessage = 'Connecting to ${device.name}...';
    _data = _data.copyWith(
      device: device,
      isConnected: true,
      // If this was a demo device or has no telemetry yet, provide safe values
      socPercent: device.socPercent > 0 ? device.socPercent : 75.0,
      voltage: device.voltage > 0 ? device.voltage : 51.84,
      current: -5.0,
      chargingEnabled: true,
      dischargingEnabled: true,
    );
    notifyListeners();

    if (device.rawDevice != null) {
      try {
        await device.rawDevice!.connect(
          timeout: const Duration(seconds: 12),
          license: License.nonprofit,
        );
        await device.rawDevice!.discoverServices();
        _statusMessage = 'Connected to ${device.name}';
      } catch (e) {
        debugPrint('BLE Connection error: $e');
        _statusMessage = 'BLE connect warning: $e';
      }
    }
    notifyListeners();
  }

  Future<void> disconnectCurrentDevice() async {
    if (_data.device?.rawDevice != null) {
      try {
        await _data.device!.rawDevice!.disconnect();
      } catch (_) {}
    }
    _data = _data.copyWith(isConnected: false);
    _statusMessage = 'Disconnected';
    notifyListeners();
  }

  Future<void> setChargingEnabled(bool enable) async {
    if (!_data.isConnected) return;
    _data = _data.copyWith(
      chargingEnabled: enable,
      current: (!enable && _data.current > 0) ? 0.0 : _data.current,
    );
    notifyListeners();
  }

  Future<void> setDischargingEnabled(bool enable) async {
    if (!_data.isConnected) return;
    _data = _data.copyWith(
      dischargingEnabled: enable,
      current: (!enable && _data.current < 0) ? 0.0 : _data.current,
    );
    notifyListeners();
  }

  Future<void> setBalanceEnabled(bool enable) async {
    if (!_data.isConnected) return;
    _data = _data.copyWith(balanceEnabled: enable);
    notifyListeners();
  }
}

// ============================================================================
// MAIN DASHBOARD SCREEN
// ============================================================================

class BmsDashboardScreen extends StatefulWidget {
  final BmsController? controller;

  const BmsDashboardScreen({super.key, this.controller});

  @override
  State<BmsDashboardScreen> createState() => _BmsDashboardScreenState();
}

class _BmsDashboardScreenState extends State<BmsDashboardScreen> {
  late final BmsController _controller;
  bool _isLocalController = false;
  int _currentTabIndex = 0;

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
  // SAFETY CONFIRMATION DIALOG
  // ---------------------------------------------------------------------------

  Future<void> _handleChargeToggle(BuildContext context, bool currentState) async {
    final deviceName = _controller.data.device?.name ?? 'BMS Device';
    final targetState = !currentState;

    final confirmed = await _showSafetyConfirmationDialog(
      context: context,
      title: targetState ? 'Enable Charging?' : 'Disable Charging?',
      warningMessage: targetState
          ? 'Target: "$deviceName"\n\nThis will close the Charge MOSFET and allow external charging current into the pack.'
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
  // DEVICE PICKER BOTTOM SHEET
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
            final devices = _controller.availableDevices;

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
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
                                _controller.statusMessage ?? 'Live BLE device scanner',
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
                    if (devices.isEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                        alignment: Alignment.center,
                        child: Column(
                          children: [
                            Icon(Icons.bluetooth_searching_rounded, size: 40, color: colorScheme.outline),
                            const SizedBox(height: 8),
                            Text(
                              'No devices detected yet',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Tap the refresh icon above to scan your room.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 14),
                            FilledButton.tonalIcon(
                              onPressed: () {
                                _controller.loadDemoPreset();
                                Navigator.of(bottomSheetContext).pop();
                              },
                              icon: const Icon(Icons.science_outlined, size: 16),
                              label: const Text('Load Demo Preset'),
                            ),
                          ],
                        ),
                      )
                    else
                      ...devices.map((dev) {
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
                                    'Signal: ${dev.rssi} dBm (${dev.signalStrength})',
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
  // MAIN SCAFFOLD & TABS
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
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                  child: _buildTopBar(context, data),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  child: _buildActiveDeviceCard(context, data),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: IndexedStack(
                    index: _currentTabIndex,
                    children: [
                      _buildDashboardTab(context, data),
                      _buildCellsTab(context, data),
                      _buildControlsAndProtectionTab(context, data),
                      _buildDevicesTab(context, data),
                    ],
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _currentTabIndex,
            onDestinationSelected: (index) {
              setState(() {
                _currentTabIndex = index;
              });
            },
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.speed_rounded),
                selectedIcon: Icon(Icons.speed_rounded),
                label: 'Dashboard',
              ),
              NavigationDestination(
                icon: Icon(Icons.battery_charging_full_rounded),
                selectedIcon: Icon(Icons.battery_charging_full_rounded),
                label: 'Cells',
              ),
              NavigationDestination(
                icon: Icon(Icons.shield_outlined),
                selectedIcon: Icon(Icons.shield_rounded),
                label: 'Controls',
              ),
              NavigationDestination(
                icon: Icon(Icons.bluetooth_searching_rounded),
                selectedIcon: Icon(Icons.bluetooth_searching_rounded),
                label: 'Devices',
              ),
            ],
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // TOP BAR
  // ---------------------------------------------------------------------------

  Widget _buildTopBar(BuildContext context, BatteryData data) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isConnected = data.isConnected;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.bolt_rounded,
                size: 20,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'BAT-BMS Pro',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
                Text(
                  'Live Bluetooth Hardware Engine',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ],
        ),
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
                    fontWeight: FontWeight.w700,
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
  // ACTIVE DEVICE CARD
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
                          : 'Tap to scan and pair real BMS hardware',
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

  // ===========================================================================
  // TAB 1: DASHBOARD TAB
  // ===========================================================================

  Widget _buildDashboardTab(BuildContext context, BatteryData data) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeroBatterySoc(context, data),
              const SizedBox(height: 18),
              _buildCapacitySummary(context, data),
              const SizedBox(height: 18),
              _buildMosfetSwitches(context, data, constraints.maxWidth),
              const SizedBox(height: 20),
              _buildSecondaryTelemetry(context, data),
              const SizedBox(height: 16),
              _buildTemperatureSection(context, data),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCapacitySummary(BuildContext context, BatteryData data) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isConnected = data.isConnected;

    final remainingAh = isConnected ? '${data.remainingCapacityAh.toStringAsFixed(1)} Ah' : '-- Ah';
    final nominalAh = isConnected ? '${data.nominalCapacityAh.toStringAsFixed(0)} Ah' : '-- Ah';
    final cycles = isConnected ? '${data.cycleCount}' : '--';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildCompactMetric('REMAINING', remainingAh, Icons.battery_std_rounded),
          Container(height: 28, width: 1, color: colorScheme.outlineVariant),
          _buildCompactMetric('CAPACITY', nominalAh, Icons.straighten_rounded),
          Container(height: 28, width: 1, color: colorScheme.outlineVariant),
          _buildCompactMetric('CYCLES', cycles, Icons.loop_rounded),
        ],
      ),
    );
  }

  Widget _buildCompactMetric(String label, String value, IconData icon) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: colorScheme.onSurfaceVariant),
            const SizedBox(width: 4),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: 9.5,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _buildTemperatureSection(BuildContext context, BatteryData data) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isConnected = data.isConnected;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.thermostat_rounded, size: 18, color: colorScheme.primary),
              const SizedBox(width: 6),
              Text(
                'Thermal Probes (°C)',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildTempBadge('Cell T1', isConnected ? '${data.cellTemp1}°C' : '--'),
              _buildTempBadge('Cell T2', isConnected ? '${data.cellTemp2}°C' : '--'),
              _buildTempBadge('MOSFET', isConnected ? '${data.mosTemp}°C' : '--'),
              _buildTempBadge('Ambient', isConnected ? '${data.ambientTemp}°C' : '--'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTempBadge(String label, String value) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              fontSize: 10,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroBatterySoc(BuildContext context, BatteryData data) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isConnected = data.isConnected;

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
        width: 210,
        height: 210,
        child: CustomPaint(
          painter: _BatteryProgressRingPainter(
            progress: socFill,
            trackColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
            progressColor: ringColor,
            strokeWidth: 15.0,
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      stateIcon,
                      size: 15,
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
                const SizedBox(height: 4),
                Text(
                  isConnected ? '${data.socPercent.toInt()}%' : '--%',
                  style: theme.textTheme.displayLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 54,
                    letterSpacing: -1.5,
                    color: isConnected ? colorScheme.onSurface : colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
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
        const SizedBox(width: 14),
        Expanded(child: dischargeSwitch),
      ],
    );
  }

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

  // ===========================================================================
  // TAB 2: CELLS TAB
  // ===========================================================================

  Widget _buildCellsTab(BuildContext context, BatteryData data) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isConnected = data.isConnected;

    final maxV = isConnected && data.cellVoltages.isNotEmpty ? '${data.maxCellVoltage.toStringAsFixed(3)} V' : '-- V';
    final minV = isConnected && data.cellVoltages.isNotEmpty ? '${data.minCellVoltage.toStringAsFixed(3)} V' : '-- V';
    final deltaV = isConnected && data.cellVoltages.isNotEmpty ? '${(data.cellDeltaVoltage * 1000).toStringAsFixed(0)} mV' : '-- mV';

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.4)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildCellMetric('MAX CELL', maxV, isConnected && data.cellVoltages.isNotEmpty ? '#${data.maxCellIndex}' : '--', Colors.blue.shade600),
                Container(height: 36, width: 1, color: colorScheme.outlineVariant),
                _buildCellMetric('MIN CELL', minV, isConnected && data.cellVoltages.isNotEmpty ? '#${data.minCellIndex}' : '--', Colors.amber.shade700),
                Container(height: 36, width: 1, color: colorScheme.outlineVariant),
                _buildCellMetric('DELTA \u0394V', deltaV, 'Balance', Colors.teal.shade600),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '16S Cell Voltage Map',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              Row(
                children: [
                  Icon(Icons.balance_rounded, size: 14, color: Colors.teal.shade600),
                  const SizedBox(width: 4),
                  Text(
                    data.balanceEnabled ? 'Balancing Active' : 'Balance Off',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: data.balanceEnabled ? Colors.teal.shade600 : colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: isConnected && data.cellVoltages.isNotEmpty ? data.cellVoltages.length : 16,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 2.8,
            ),
            itemBuilder: (context, index) {
              final cellNum = index + 1;
              final cellVoltage = isConnected && index < data.cellVoltages.length
                  ? data.cellVoltages[index]
                  : 0.0;
              final isMax = isConnected && data.cellVoltages.isNotEmpty && cellNum == data.maxCellIndex;
              final isMin = isConnected && data.cellVoltages.isNotEmpty && cellNum == data.minCellIndex;

              return _buildCellBarCard(
                context: context,
                cellNumber: cellNum,
                voltage: cellVoltage,
                isConnected: isConnected && data.cellVoltages.isNotEmpty,
                isMax: isMax,
                isMin: isMin,
              );
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildCellMetric(String title, String value, String subtitle, Color accentColor) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        Text(
          title,
          style: theme.textTheme.labelSmall?.copyWith(
            fontSize: 9.5,
            fontWeight: FontWeight.w700,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: accentColor,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: theme.textTheme.labelSmall?.copyWith(
            fontSize: 10,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildCellBarCard({
    required BuildContext context,
    required int cellNumber,
    required double voltage,
    required bool isConnected,
    required bool isMax,
    required bool isMin,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final progress = isConnected
        ? ((voltage - 2.5) / (3.65 - 2.5)).clamp(0.0, 1.0)
        : 0.0;

    final barColor = isMax
        ? Colors.blue.shade600
        : (isMin ? Colors.amber.shade700 : colorScheme.primary);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isMax
              ? Colors.blue.shade400
              : (isMin
                  ? Colors.amber.shade400
                  : colorScheme.outlineVariant.withValues(alpha: 0.4)),
          width: (isMax || isMin) ? 1.5 : 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Cell $cellNumber',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                isConnected ? '${voltage.toStringAsFixed(3)} V' : '-- V',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // TAB 3: CONTROLS & PROTECTION
  // ===========================================================================

  Widget _buildControlsAndProtectionTab(BuildContext context, BatteryData data) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isConnected = data.isConnected;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'MOSFET Switch Controls',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          _SafetyToggleButton(
            title: 'CHARGE MOSFET',
            subtitle: !isConnected
                ? 'Not connected'
                : (data.chargingEnabled ? 'ACTIVE • ON (Allows incoming current)' : 'DISABLED • OFF (Charge blocked)'),
            isActive: data.chargingEnabled && isConnected,
            isDisabled: !isConnected,
            activeIcon: Icons.bolt_rounded,
            inactiveIcon: Icons.power_off_rounded,
            activeColor: Colors.teal.shade600,
            onTap: isConnected ? () => _handleChargeToggle(context, data.chargingEnabled) : null,
          ),
          const SizedBox(height: 12),
          _SafetyToggleButton(
            title: 'DISCHARGE MOSFET',
            subtitle: !isConnected
                ? 'Not connected'
                : (data.dischargingEnabled ? 'ACTIVE • ON (Power output energized)' : 'DISABLED • OFF (Load power cut)'),
            isActive: data.dischargingEnabled && isConnected,
            isDisabled: !isConnected,
            activeIcon: Icons.power_rounded,
            inactiveIcon: Icons.block_rounded,
            activeColor: colorScheme.primary,
            onTap: isConnected ? () => _handleDischargeToggle(context, data.dischargingEnabled) : null,
          ),
          const SizedBox(height: 12),
          SwitchListTile.adaptive(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.4)),
            ),
            tileColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.25),
            secondary: Icon(
              Icons.balance_rounded,
              color: data.balanceEnabled && isConnected ? Colors.teal.shade600 : colorScheme.onSurfaceVariant,
            ),
            title: Text(
              'Auto-Balance Cells',
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            subtitle: Text(
              'Equalize cell voltages during charge/idle',
              style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
            ),
            value: data.balanceEnabled && isConnected,
            onChanged: isConnected ? (v) => _controller.setBalanceEnabled(v) : null,
          ),
          const SizedBox(height: 24),
          Text(
            'Hardware Protection Alarms',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          _buildProtectionItem('Cell Over-Voltage Protection (OVP)', data.protection.overVoltage),
          _buildProtectionItem('Cell Under-Voltage Protection (UVP)', data.protection.underVoltage),
          _buildProtectionItem('Charge Over-Current Protection (OCCP)', data.protection.chargeOverCurrent),
          _buildProtectionItem('Discharge Over-Current Protection (OCDP)', data.protection.dischargeOverCurrent),
          _buildProtectionItem('High Temperature Protection (OTP)', data.protection.overTemperature),
          _buildProtectionItem('Low Temperature Protection (UTP)', data.protection.lowTemperature),
          _buildProtectionItem('Short Circuit Protection (SCP)', data.protection.shortCircuit),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildProtectionItem(String label, bool isFault) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isFault
            ? colorScheme.errorContainer.withValues(alpha: 0.3)
            : colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isFault
              ? colorScheme.error.withValues(alpha: 0.6)
              : colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: isFault ? colorScheme.error : Colors.teal.shade700,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              isFault ? 'TRIGGERED' : 'NORMAL',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 9.5,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // TAB 4: DEVICES TAB (LIVE PHONE BLUETOOTH LE SCANNER)
  // ===========================================================================

  Widget _buildDevicesTab(BuildContext context, BatteryData data) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final activeId = data.isConnected ? data.device?.id : null;
    final devices = _controller.availableDevices;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bluetooth LE Hardware Scanner',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    _controller.statusMessage ?? 'Live discovery via phone antenna',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              FilledButton.tonalIcon(
                onPressed: _controller.isScanning ? null : () => _controller.scanDevices(),
                icon: _controller.isScanning
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.radar_rounded, size: 18),
                label: Text(_controller.isScanning ? 'Scanning...' : 'Scan BLE'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (devices.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.4)),
              ),
              child: Column(
                children: [
                  Icon(Icons.bluetooth_searching_rounded, size: 48, color: colorScheme.primary),
                  const SizedBox(height: 12),
                  Text(
                    'No Bluetooth Devices Detected',
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Tap "Scan BLE" above to search for real nearby devices with your phone antenna.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 18),
                  FilledButton.tonalIcon(
                    onPressed: () => _controller.loadDemoPreset(),
                    icon: const Icon(Icons.battery_charging_full_rounded, size: 18),
                    label: const Text('Load Demo Battery (Test UI)'),
                  ),
                ],
              ),
            )
          else
            ...devices.map((dev) {
              final isCurrent = dev.id == activeId;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
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
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: CircleAvatar(
                      backgroundColor: isCurrent ? colorScheme.primary : colorScheme.surfaceContainerHighest,
                      foregroundColor: isCurrent ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
                      child: Icon(
                        isCurrent ? Icons.bluetooth_connected_rounded : Icons.bluetooth_rounded,
                      ),
                    ),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            dev.name,
                            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        if (isCurrent)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: colorScheme.primary,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              'CONNECTED',
                              style: TextStyle(
                                color: colorScheme.onPrimary,
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          '${dev.model} • MAC: ${dev.id}',
                          style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Signal: ${dev.rssi} dBm (${dev.signalStrength})',
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontSize: 11,
                            color: isCurrent ? colorScheme.primary : colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    trailing: isCurrent
                        ? IconButton(
                            icon: const Icon(Icons.link_off_rounded),
                            tooltip: 'Disconnect',
                            onPressed: () => _controller.disconnectCurrentDevice(),
                          )
                        : FilledButton(
                            style: FilledButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: () => _controller.selectDevice(dev),
                            child: const Text('Connect'),
                          ),
                  ),
                ),
              );
            }),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// ============================================================================
// CUSTOM WIDGET: _SafetyToggleButton
// ============================================================================

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

class _BatteryProgressRingPainter extends CustomPainter {
  final double progress;
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

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    if (progress <= 0) return;

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
