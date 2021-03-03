import 'package:flutter/widgets.dart';
import 'package:flutter_ble_lib/flutter_ble_lib.dart';
import 'package:jump/src/services/lib/ble-service/device_repository.dart';
import 'package:jump/src/services/lib/ble-service/ble_service.dart';

class BleServiceProvider extends InheritedWidget {
  final BleService bleService;

  BleServiceProvider({
    Key key,
    BleService bleService,
    Widget child,
  })  : bleService =
            bleService ?? BleService(DeviceRepository(), BleManager()),
        super(key: key, child: child);

  @override
  bool updateShouldNotify(InheritedWidget oldWidget) => true;

  static BleService of(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<BleServiceProvider>()
      .bleService;
}
