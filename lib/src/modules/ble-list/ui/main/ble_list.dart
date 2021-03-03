import 'dart:async';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:jump/src/modules/future-map/ui/widgets/component/app_bar.dart';
import 'package:jump/src/modules/future-map/ui/widgets/component/ink_well.dart';
import 'package:jump/src/services/lib/ble-service/ble_device.dart';
import 'package:jump/src/services/lib/ble-service/ble_service.dart';
import 'package:jump/src/services/lib/ble-service/ble_service_provider.dart';

typedef DeviceTapListener = void Function();

class BleListModuleMainWidget extends StatefulWidget {
  @override
  State<BleListModuleMainWidget> createState() => _BleListState();
}

class _BleListState extends State<BleListModuleMainWidget> {
  BleService _bleService;
  StreamSubscription _appStateSubscription;
  bool _shouldRunOnResume = true;

  @override
  void didUpdateWidget(BleListModuleMainWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    print('didUpdateWidget');
  }

  void _onPause() {
    print('onPause');
    _appStateSubscription.cancel();
    _bleService.dispose();
  }

  void _onResume() {
    print('onResume');
    _bleService.init();
    _appStateSubscription = _bleService.pickedDevice.listen((bleDevice) async {
      print('navigate to detail');
      _onPause();
      await Navigator.pushNamed(context, '/detail');
      setState(() {
        _shouldRunOnResume = true;
      });
      print('back from detail');
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    print('_BleListState didChangeDependencies');
    if (_bleService == null) {
      _bleService = BleServiceProvider.of(context);
      if (_shouldRunOnResume) {
        _shouldRunOnResume = false;
        _onResume();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    print('build _BleListState');
    if (_shouldRunOnResume) {
      _shouldRunOnResume = false;
      _onResume();
    }
    return Scaffold(
      appBar: MAppBar(
        title: 'Bluetooth Devices',
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _bleService.refresh,
        backgroundColor: const Color(0xFF00539E),
        tooltip: 'Search Devices',
        child: Icon(FontAwesomeIcons.search),
      ),
      body: Column(
        key: ValueKey('Ble List'),
        children: [
          const SizedBox(
            height: 10.0,
          ),
          Center(
            child: Text('BLE Device List'),
          ),
          const SizedBox(
            height: 5.0,
          ),
          Expanded(
            child: StreamBuilder<List<BleDevice>>(
              initialData: _bleService.visibleDevices.value,
              stream: _bleService.visibleDevices,
              builder: (context, snapshot) => RefreshIndicator(
                onRefresh: _bleService.refresh,
                child: DevicesList(_bleService, snapshot.data),
              ),
            ),
          ),
          const SizedBox(
            height: 15.0,
          ),
        ],
      ),
    );
  }
}

class DevicesList extends ListView {
  DevicesList(BleService bleService, List<BleDevice> devices)
      : super.separated(
            separatorBuilder: (context, index) => Divider(
                  color: Colors.grey[300],
                  height: 0,
                  indent: 0,
                ),
            itemCount: devices.length,
            itemBuilder: (context, i) {
              print('Build row for $i');
              return _buildRow(context, devices[i],
                  _createTapListener(bleService, devices[i]));
            });

  static DeviceTapListener _createTapListener(
      BleService bleService, BleDevice bleDevice) {
    return () {
      print('clicked device: ${bleDevice.name}');
      bleService.devicePicker.add(bleDevice);
    };
  }

  static Widget _buildRow(BuildContext context, BleDevice device,
      DeviceTapListener deviceTapListener) {
    return Card(
      elevation: 5.0,
      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(
          Radius.circular(4.0),
        ),
      ),
      child: MInkWell(
        onPressed: deviceTapListener,
        child: Column(
          children: [
            ListTile(
              title: Text(
                device.name,
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text('Device Name'),
              leading: Icon(
                FontAwesomeIcons.bluetooth,
                color: const Color(0xFF00AAFF),
              ),
              trailing: IconButton(
                icon: Icon(
                  FontAwesomeIcons.slidersH,
                  color: const Color(0xFF00AAFF),
                ),
                onPressed: deviceTapListener,
              ),
            ),
            ListTile(
              title: Text(
                device.id.toString(),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
              subtitle: Text('Device ID'),
              leading: Icon(
                FontAwesomeIcons.mapPin,
                color: const Color(0xFF00AAFF),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
