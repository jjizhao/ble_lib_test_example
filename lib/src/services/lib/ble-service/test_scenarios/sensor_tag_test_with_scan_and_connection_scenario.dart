part of test_scenarios;

class SensorTagTestWithScanAndConnectionScenario implements TestScenario {
  BleManager bleManager = BleManager();
  bool deviceConnectionAttempted = false;

  @override
  Future<void> runTestScenario(Logger log, Logger logError) async {
    log('========CREATING CLIENT...');
    await bleManager.createClient(
        restoreStateIdentifier: '5',
        restoreStateAction: (devices) {
          log('========RESTORED DEVICES: $devices');
        });

    log('========CREATED CLIENT');
    log('========STARTING SCAN...');
    log('========Looking for Sensor Tag...');

    bleManager.startPeripheralScan().listen((scanResult) async {
      log('========RECEIVED SCAN RESULT: '
          '  name: ${scanResult.peripheral.name}'
          '  identifier: ${scanResult.peripheral.identifier}'
          '  rssi: ${scanResult.rssi}');

      if (scanResult.peripheral.name == 'SensorTag' &&
          !deviceConnectionAttempted) {
        log('========Sensor Tag found!========');
        deviceConnectionAttempted = true;
        log('========Stopping device scan...');
        await bleManager.stopPeripheralScan();
        return _tryToConnect(scanResult.peripheral, log, logError);
      }
    }, onError: (error) {
      logError(error);
    });
  }

  Future<void> _tryToConnect(
      Peripheral peripheral, Logger log, Logger logError) async {
    log('========OBSERVING connection state  for ${peripheral.name},'
        ' ${peripheral.identifier}...');

    peripheral
        .observeConnectionState(emitCurrentValue: true)
        .listen((connectionState) {
      log('========Current connection state is:   $connectionState');
      if (connectionState == PeripheralConnectionState.disconnected) {
        log('========${peripheral.name} has DISCONNECTED');
      }
    });

    log('========CONNECTING to ${peripheral.name}, ${peripheral.identifier}...');
    await peripheral.connect();
    log('========CONNECTED to ${peripheral.name}, ${peripheral.identifier}!========');
    deviceConnectionAttempted = false;

    await peripheral
        .discoverAllServicesAndCharacteristics()
        .then((_) => peripheral.services())
        .then((services) {
          log('========PRINTING SERVICES for ${peripheral.name}');
          services.forEach(
              (service) => log('========Found service ${service.uuid}'));
          return services.first;
        })
        .then((service) async {
          log('========PRINTING CHARACTERISTICS FOR SERVICE  ${service.uuid}');
          var characteristics = await service.characteristics();
          characteristics.forEach((characteristic) {
            log('========${characteristic.uuid}');
          });

          log('========PRINTING CHARACTERISTICS FROM  PERIPHERAL for the same service');
          return peripheral.characteristics(service.uuid);
        })
        .then((characteristics) => characteristics.forEach((characteristic) =>
            log('========Found characteristic   ${characteristic.uuid}')))
        .then((_) {
          log('========WAITING 10 SECOND BEFORE DISCONNECTING');
          return Future.delayed(Duration(seconds: 10));
        })
        .then((_) {
          log('========DISCONNECTING...');
          return peripheral.disconnectOrCancelConnection();
        })
        .then((_) {
          log('========Disconnected!========');
          log('========WAITING 10 SECOND BEFORE DESTROYING CLIENT');
          return Future.delayed(Duration(seconds: 10));
        })
        .then((_) {
          log('========DESTROYING client...');
          return bleManager.destroyClient();
        })
        .then((_) => log('========\BleClient destroyed after a delay'));
  }
}
