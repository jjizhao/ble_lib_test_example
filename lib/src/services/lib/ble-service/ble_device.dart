import 'package:collection/collection.dart';
import 'package:flutter_ble_lib/flutter_ble_lib.dart';

class BleDevice {
  final Peripheral peripheral;
  final String name;
  final DeviceCategory category;

  String get id => peripheral.identifier;

  BleDevice(ScanResult scanResult)
      : peripheral = scanResult.peripheral,
        name = scanResult.name,
        category = scanResult.category;

  @override
  int get hashCode => id.hashCode;

  @override
  bool operator ==(other) =>
      other is BleDevice &&
      name != null &&
      other.name != null &&
      compareAsciiLowerCase(name, other.name) == 0 &&
      id == other.id;

  @override
  String toString() {
    return 'BleDevice{name: $name}';
  }
}

enum DeviceCategory { sensorTag, hex, other }

extension on ScanResult {
  String get name =>
      peripheral.name ?? advertisementData.localName ?? 'Unknown';

  DeviceCategory get category {
    if (name == 'SensorTag') {
      return DeviceCategory.sensorTag;
    } else if (name != null && name.startsWith('Hex')) {
      return DeviceCategory.hex;
    } else {
      return DeviceCategory.other;
    }
  }
}
