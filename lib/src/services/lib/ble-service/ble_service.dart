import 'dart:async';
import 'dart:io';
import 'package:rxdart/rxdart.dart';
import 'package:flutter_ble_lib/flutter_ble_lib.dart';
import 'package:jump/src/services/lib/ble-service/ble_config.dart';
import 'package:jump/src/services/lib/ble-service/ble_device.dart';
import 'package:jump/src/services/lib/ble-service/device_repository.dart';
import 'package:permission_handler/permission_handler.dart';

class BleService {
  final List<BleDevice> bleList = <BleDevice>[];

  BehaviorSubject<List<BleDevice>> _visibleDevicesController =
      BehaviorSubject<List<BleDevice>>.seeded(<BleDevice>[]);

  StreamController<BleDevice> _devicePickerController =
      StreamController<BleDevice>();

  StreamSubscription<ScanResult> _scanSubscription;
  StreamSubscription _devicePickerSubscription;

  ValueStream<List<BleDevice>> get visibleDevices =>
      _visibleDevicesController.stream;

  Sink<BleDevice> get devicePicker => _devicePickerController.sink;

  final DeviceRepository _deviceRepository;
  final BleManager _bleManager;
  PermissionStatus _locationPermissionStatus = PermissionStatus.unknown;

  Stream<BleDevice> get pickedDevice => _deviceRepository.pickedDevice
      .skipWhile((bleDevice) => bleDevice == null);

  BleService(this._deviceRepository, this._bleManager);

  void _handlePickedDevice(BleDevice bleDevice) {
    _deviceRepository.pickDevice(bleDevice);
  }

  void dispose() {
    print('cancel _devicePickerSubscription');
    _devicePickerSubscription.cancel();
    _visibleDevicesController.close();
    _devicePickerController.close();
    _scanSubscription?.cancel();
  }

  void init() {
    print('Init device service');
    bleList.clear();
    _bleManager
        .createClient(
            restoreStateIdentifier: 'example-restore-state-identifier',
            restoreStateAction: (peripherals) {
              peripherals?.forEach((peripheral) {
                print('Restored peripheral: ${peripheral.name}');
              });
            })
        .catchError((e) => print('Couldn\'t create BLE client' + e.toString()))
        .then((_) => _checkPermissions())
        .catchError((e) => print('Permission check error' + e.toString()))
        .then((_) => _waitForBluetoothPoweredOn())
        .then((_) => _startScan());

    if (_visibleDevicesController.isClosed) {
      _visibleDevicesController =
          BehaviorSubject<List<BleDevice>>.seeded(<BleDevice>[]);
    }

    if (_devicePickerController.isClosed) {
      _devicePickerController = StreamController<BleDevice>();
    }

    print(' listen to _devicePickerController.stream');
    _devicePickerSubscription =
        _devicePickerController.stream.listen(_handlePickedDevice);
  }

  Future<void> _checkPermissions() async {
    if (Platform.isAndroid) {
      var permissionStatus = await PermissionHandler()
          .requestPermissions([PermissionGroup.location]);

      _locationPermissionStatus = permissionStatus[PermissionGroup.location];

      if (_locationPermissionStatus != PermissionStatus.granted) {
        return Future.error(Exception('Location permission not granted'));
      }
    }
  }

  Future<void> _waitForBluetoothPoweredOn() async {
    var completer = Completer();
    StreamSubscription<BluetoothState> subscription;
    subscription = _bleManager
        .observeBluetoothState(emitCurrentValue: true)
        .listen((bluetoothState) async {
      if (bluetoothState == BluetoothState.POWERED_ON &&
          !completer.isCompleted) {
        await subscription.cancel();
        completer.complete();
      }
    });
    return completer.future;
  }

  void _startScan() {
    print('Ble client created');
    _scanSubscription = _bleManager
        .startPeripheralScan(uuids: [JciServiceUuids.jciServiceUuid]).listen(
            (ScanResult scanResult) {
      var bleDevice = BleDevice(scanResult);
      if (scanResult.advertisementData.localName != null &&
          !bleList.contains(bleDevice)) {
        print(
            'found new device ${scanResult.advertisementData.localName} ${scanResult.peripheral.identifier}');
        bleList.add(bleDevice);
        _visibleDevicesController.add(bleList.sublist(0));
      }
    });
  }

  Future<void> refresh() async {
    await _scanSubscription.cancel();
    await _bleManager.stopPeripheralScan();
    bleList.clear();
    _visibleDevicesController.add(bleList.sublist(0));
    await _checkPermissions()
        .then((_) => _startScan())
        .catchError((e) => print('Couldn\'t refresh' + e.toString()));
  }
}
