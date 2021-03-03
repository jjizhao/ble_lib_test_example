import 'package:flutter/widgets.dart';
import 'package:flutter_ble_lib/flutter_ble_lib.dart';
import 'package:jump/src/services/lib/ble-service/device_repository.dart';

import 'device_detail_service.dart';

class DeviceDetailServiceProvider extends InheritedWidget {
  final DeviceDetailService deviceDetailService;

  DeviceDetailServiceProvider({
    Key key,
    DeviceDetailService deviceDetailService,
    Widget child,
  })  : deviceDetailService = deviceDetailService ??
            DeviceDetailService(DeviceRepository(), BleManager()),
        super(key: key, child: child);

  @override
  bool updateShouldNotify(InheritedWidget oldWidget) => true;

  static DeviceDetailService of(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<DeviceDetailServiceProvider>()
      .deviceDetailService;
}
