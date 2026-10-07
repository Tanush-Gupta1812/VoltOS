# ⚡ VoltOS — Real-Time Battery Management System (BMS) Monitor

**VoltOS** is a telemetry dashboard and mobile diagnostic suite built for hardware engineers, EV builders, and robotics teams. Developed with **Flutter** and **Bluetooth Low Energy (BLE)**, VoltOS delivers live cell-level analytics, protection status monitoring, and thermal diagnostics from physical BMS hardware directly to your phone.

---

## 🔋 Core Capabilities

- 📡 **BLE Auto-Discovery & Telemetry**: Scans and bonds with BLE-enabled Battery Management Systems (BMS), streaming live metrics with sub-second latency.
- ⚡ **Individual Cell Voltage & Balancing**: Real-time inspection of individual series cell voltages (mV), delta variance, and active cell balancing indicators.
- 🛡️ **Hardware Protection Alarms**: Real-time status flags for:
  - Over-voltage & Under-voltage cutoffs
  - Over-current (Charge & Discharge)
  - Temperature anomalies (High/Low temperature cutoffs)
  - Short-circuit protection events
- 📊 **State of Charge (SoC) & Capacity**: Live tracking of capacity (Ah), percentage SoC, power draw (Watts), and estimated runtime.
- 🌙 **Automotive HUD Aesthetics**: Dark mode telemetry cockpit featuring high-contrast electric cyan accents, designed for clarity in both workshop and field conditions.

---

## 🛠️ Technology Stack

- **Framework**: [Flutter](https://flutter.dev/) (Dart 3+)
- **Hardware Communication**: [flutter_blue_plus](https://pub.dev/packages/flutter_blue_plus) (Bluetooth LE)
- **UI & Architecture**: Material 3 with customized dark telemetry theme
- **Target Platforms**: Android & iOS

---

## 🚀 Getting Started

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (v3.13+)
- Physical Android or iOS device with Bluetooth 4.2+ / BLE support *(Emulators cannot scan physical BLE peripherals)*

### Running the App

1. **Clone the repository**:
   ```bash
   git clone https://github.com/Tanush-Gupta1812/VoltOS.git
   cd VoltOS
   ```

2. **Install Flutter packages**:
   ```bash
   flutter pub get
   ```

3. **Deploy to physical device**:
   ```bash
   flutter run -d <your-device-id>
   ```

4. **Permissions**: Grant Bluetooth and Location permissions when prompted to enable BLE peripheral scanning.

---

## 📂 Project Structure

```text
VoltOS/
├── lib/
│   ├── main.dart                      # App entry point, system theme configuration
│   └── screens/
│       └── bms_dashboard_screen.dart  # Telemetry cockpit, BLE connection manager,
│                                      # cell monitoring grid, and protection alarms
├── pubspec.yaml                       # Dependencies & BLE permissions
└── android/                           # Native Android manifest with Bluetooth config
```

---

## 📄 License
Released under the [MIT License](LICENSE).
