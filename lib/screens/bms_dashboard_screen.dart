import 'dart:math' as math;
import 'package:flutter/material.dart';

// ============================================================================
// MODEL: BatteryData
// ============================================================================

/// Immutable telemetry model representing live battery status.
class BatteryData {
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
    double? socPercent,
    double? voltage,
    double? current,
    bool? chargingEnabled,
    bool? dischargingEnabled,
    bool? isConnected,
  }) {
    return BatteryData(
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
/// 2. **Clean Separation of Concerns**: Decouples the safety-critical MOSFET logic
///    and BLE hardware communication from widget presentation.
/// 3. **Interoperable**: Can be directly consumed via [ListenableBuilder], or
///    easily adapted to Riverpod (`ChangeNotifierProvider`), Provider, or Streams.
class BmsController extends ChangeNotifier {
  BatteryData _data;

  BmsController({BatteryData? initialData})
      : _data = initialData ?? BatteryData.mockDefault;

  BatteryData get data => _data;

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
  // SAFETY CONFIRMATION DIALOG
  // ---------------------------------------------------------------------------

  Future<void> _handleChargeToggle(BuildContext context, bool currentState) async {
    final targetState = !currentState;
    final confirmed = await _showSafetyConfirmationDialog(
      context: context,
      title: targetState ? 'Enable Charging?' : 'Disable Charging?',
      warningMessage: targetState
          ? 'This will close the Charge MOSFET and allow external current to flow into the battery. Ensure charger voltage and limits are compatible.'
          : 'This will open the Charge MOSFET. The battery will immediately stop accepting power from chargers and solar inputs.',
      actionLabel: targetState ? 'Enable Charge' : 'Turn OFF Charge',
      isDestructive: !targetState,
    );

    if (confirmed == true && mounted) {
      await _controller.setChargingEnabled(targetState);
    }
  }

  Future<void> _handleDischargeToggle(BuildContext context, bool currentState) async {
    final targetState = !currentState;
    final confirmed = await _showSafetyConfirmationDialog(
      context: context,
      title: targetState ? 'Enable Discharging?' : 'Cut Power Output?',
      warningMessage: targetState
          ? 'This will close the Discharge MOSFET and energize all connected equipment, inverters, and loads.'
          : 'Turn OFF discharge? This will immediately open the MOSFET and CUT POWER to all connected loads and devices.',
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
                        // --- 1. Minimal Header with Connection Indicator ---
                        _buildHeader(context, data),

                        const SizedBox(height: 20),

                        // --- 2. Primary Element: Hero Battery SOC Ring & Percentage ---
                        _buildHeroBatterySoc(context, data),

                        const SizedBox(height: 32),

                        // --- 3. Safety-Relevant MOSFET Controls (Charge / Discharge) ---
                        _buildMosfetSwitches(context, data, constraints.maxWidth),

                        const SizedBox(height: 32),

                        // --- 4. Visually Secondary Telemetry Row (Voltage, Current, Power) ---
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
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
                color: colorScheme.onSurface,
              ),
            ),
            Text(
              'VoltOS v1.0',
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
        // Interactive connection badge (tap to toggle for testing/simulation)
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
