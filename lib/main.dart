import 'package:flutter/material.dart';
import 'package:jump/src/modules/ble-list/ui/main/ble_list.dart';
import 'package:jump/src/modules/ble-list/ui/views/device_detail_view.dart';
import 'package:jump/src/services/lib/ble-service/ble_service_provider.dart';
import 'package:jump/src/services/lib/ble-service/device_detail_service_provider.dart';

void main() {
  runApp(MyApp());
}

final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FlutterBleLib example',
      initialRoute: '/',
      routes: <String, WidgetBuilder>{
        '/': (context) => BleServiceProvider(child: BleListModuleMainWidget()),
        '/detail': (context) =>
            DeviceDetailServiceProvider(child: DeviceDetailView()),
      },
      navigatorObservers: [routeObserver],
    );
  }
}
