import 'dart:async';

import 'package:flutter/material.dart';
import 'package:jump/src/modules/ble-list/ui/widgets/logs_container_view.dart';
import 'package:jump/src/modules/future-map/ui/widgets/component/app_bar.dart';
import 'package:jump/src/services/lib/ble-service/device_detail_service.dart';
import 'package:jump/src/services/lib/ble-service/device_detail_service_provider.dart';

class DeviceDetailView extends StatefulWidget {
  @override
  State<DeviceDetailView> createState() => DeviceDetailViewState();
}

class DeviceDetailViewState extends State<DeviceDetailView> {
  DeviceDetailService _deviceDetailService;
  StreamSubscription _appStateSubscription;

  bool _shouldRunOnResume = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    print('didChangeDependencies');
    if (_deviceDetailService == null) {
      _deviceDetailService = DeviceDetailServiceProvider.of(context);
      if (_shouldRunOnResume) {
        _shouldRunOnResume = false;
        _onResume();
      }
    }
  }

  void _onResume() {
    print('onResume');
    _deviceDetailService.init();
    _appStateSubscription =
        _deviceDetailService.disconnectedDevice.listen((bleDevice) async {
      print('navigate to detail');
      _onPause();
      Navigator.pop(context);
      _shouldRunOnResume = true;
      print('back from detail');
    });
  }

  void _onPause() {
    print('onPause');
    _appStateSubscription.cancel();
    _deviceDetailService.dispose();
  }

  @override
  void dispose() {
    print('Dispose _BleListState');
    _onPause();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () {
        return _deviceDetailService.disconnect().then((_) {
          return false;
        });
      },
      child: DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: MAppBar(
            title: 'Device Detail',
          ),
          body: Column(children: <Widget>[
            RaisedButton(
              onPressed: _deviceDetailService.startAutoTest,
              child: Text('Start Auto Test'),
            ),
            Expanded(
              flex: 19,
              child: LogsContainerView(_deviceDetailService.logs),
            )
          ]),
        ),
      ),
    );
  }
}
