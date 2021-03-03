part of test_scenarios;

typedef TestedFunction = Future<void> Function();

class PeripheralTestOperations {
  final Peripheral peripheral;
  final Logger log;
  final Logger logError;
  StreamSubscription monitoringStreamSubscription;
  final BleManager bleManager;

  PeripheralTestOperations(
      this.bleManager, this.peripheral, this.log, this.logError);

  Future<void> connect() async {
    await _runWithErrorHandling(() async {
      log('========Connecting to ${peripheral.name}');
      await peripheral.connect();
      log('========Connected!========');
    });
  }

  Future<void> cancelTransaction() async {
    await _runWithErrorHandling(() async {
      log('========Starting operation to cancel...');
      await peripheral
          .discoverAllServicesAndCharacteristics(transactionId: 'test')
          .catchError((error) {
        var bleError = error as BleError;
        return logError('Cancelled operation caught an error: '
            ' error code ${bleError.errorCode.value},'
            ' reason: ${bleError.reason}');
      });
      log('========Operation to cancel started: discover all'
          ' services and characteristics');

      log('========Cancelling operation...');
      await bleManager.cancelTransaction('test');
      log('========Operation cancelled!========');
    });
  }

  Future<void> discovery() async => await _runWithErrorHandling(() async {
        await peripheral.discoverAllServicesAndCharacteristics();
        var services = await peripheral.services();
        log('========PRINTING SERVICES for ${peripheral.name}');
        services
            .forEach((service) => log('========Found service ${service.uuid}'));
        var service = services.first;
        log('========PRINTING CHARACTERISTICS FOR SERVICE ${service.uuid}');

        var characteristics = await service.characteristics();
        characteristics.forEach((characteristic) {
          log('========${characteristic.uuid}');
        });

        log('========PRINTING CHARACTERISTICS FROM  PERIPHERAL for the same service');
        var characteristicFromPeripheral =
            await peripheral.characteristics(service.uuid);
        characteristicFromPeripheral.forEach((characteristic) =>
            log('========Found characteristic   ${characteristic.uuid}'));

        //------------ descriptors
        List<Descriptor> descriptors;

        var printDescriptors = () => descriptors.forEach((descriptor) {
              log('========Descriptor: ${descriptor.uuid}');
            });

        log('========Using IR Jci service/IR Jci Data '
            'characteristic for following descriptor tests');
        log('========PRINTING DESCRIPTORS FOR PERIPHERAL');

        descriptors = await peripheral.descriptorsForCharacteristic(
            JciServiceUuids.jciServiceUuid,
            JciServiceUuids.jciDataCharacteristic);

        printDescriptors();
        descriptors = null;

        log('========PRINTING DESCRIPTORS FOR SERVICE');
        var chosenService = services.firstWhere((elem) =>
            elem.uuid == JciServiceUuids.jciServiceUuid.toLowerCase());

        descriptors = await chosenService.descriptorsForCharacteristic(
            JciServiceUuids.jciDataCharacteristic);

        printDescriptors();
        descriptors = null;

        var jciCharacteristics = await chosenService.characteristics();
        var chosenCharacteristic = jciCharacteristics.first;

        log('========PRINTING DESCRIPTORS FOR CHARACTERISTIC');
        descriptors = await chosenCharacteristic.descriptors();

        printDescriptors();
      });

  Future<void> testReadingRssi() async {
    await _runWithErrorHandling(() async {
      var rssi = await peripheral.rssi();
      log('========rssi $rssi');
    });
  }

  Future<void> testRequestingMtu() async {
    await _runWithErrorHandling(() async {
      var requestedMtu = 79;
      log('========Requesting MTU = $requestedMtu');
      var negotiatedMtu = await peripheral.requestMtu(requestedMtu);
      log('========negotiated MTU $negotiatedMtu');
    });
  }

  Future<void> readCharacteristicForPeripheral() async {
    await _runWithErrorHandling(() async {
      log('========Reading jci config');
      var readValue = await peripheral.readCharacteristic(
          JciServiceUuids.jciServiceUuid,
          JciServiceUuids.jciDataCharacteristic);
      log('========Jci config value:  ${_convertToJci(readValue.value)}C');
    });
  }

  Future<void> readCharacteristicForService() async {
    await _runWithErrorHandling(() async {
      log('========Reading jci config');
      var service = await peripheral.services().then((services) =>
          services.firstWhere((service) =>
              service.uuid == JciServiceUuids.jciServiceUuid.toLowerCase()));
      var readValue = await service
          .readCharacteristic(JciServiceUuids.jciDataCharacteristic);
      log('========Jci config value:  ${_convertToJci(readValue.value)}C');
    });
  }

  Future<void> readCharacteristic() async {
    await _runWithErrorHandling(() async {
      log('========Reading jci config');
      var service = await peripheral.services().then((services) =>
          services.firstWhere((service) =>
              service.uuid == JciServiceUuids.jciServiceUuid.toLowerCase()));

      var characteristics = await service.characteristics();
      var characteristic = characteristics.firstWhere((characteristic) =>
          characteristic.uuid ==
          JciServiceUuids.jciDataCharacteristic.toLowerCase());

      var readValue = await characteristic.read();
      log('========Jci config value:  ${_convertToJci(readValue)}C');
    });
  }

  Future<void> writeCharacteristicForPeripheral() async {
    await _runWithErrorHandling(() async {
      var currentValue = await peripheral
          .readCharacteristic(JciServiceUuids.jciServiceUuid,
              JciServiceUuids.jciConfigCharacteristic)
          .then((characteristic) => characteristic.value);

      int valueToSave;
      if (currentValue[0] == 0) {
        log('========Turning on jci update via peripheral');
        valueToSave = 1;
      } else {
        log('========Turning off jci update via peripheral');
        valueToSave = 0;
      }

      await peripheral.writeCharacteristic(
          JciServiceUuids.jciServiceUuid,
          JciServiceUuids.jciConfigCharacteristic,
          Uint8List.fromList([valueToSave]),
          false);

      log('========Written \'$valueToSave\' to jci config');
    });
  }

  Future<void> writeCharacteristicForService() async {
    await _runWithErrorHandling(() async {
      var service = await peripheral.services().then((services) =>
          services.firstWhere((service) =>
              service.uuid == JciServiceUuids.jciServiceUuid.toLowerCase()));

      var currentValue = await service
          .readCharacteristic(JciServiceUuids.jciConfigCharacteristic)
          .then((characteristic) => characteristic.value);

      int valueToSave;
      if (currentValue[0] == 0) {
        log('========Turning on jci update via service');
        valueToSave = 1;
      } else {
        log('========Turning off jci update via service');
        valueToSave = 0;
      }

      await service.writeCharacteristic(JciServiceUuids.jciConfigCharacteristic,
          Uint8List.fromList([valueToSave]), false);

      log('========Written \'$valueToSave\' to jci config');
    });
  }

  Future<void> writeCharacteristic() async {
    await _runWithErrorHandling(() async {
      var service = await peripheral.services().then((services) =>
          services.firstWhere((service) =>
              service.uuid == JciServiceUuids.jciServiceUuid.toLowerCase()));

      var characteristics = await service.characteristics();
      var characteristic = characteristics.firstWhere((characteristic) =>
          characteristic.uuid ==
          JciServiceUuids.jciConfigCharacteristic.toLowerCase());
      var currentValue = await characteristic.read();
      int valueToSave;
      if (currentValue[0] == 0) {
        log('========Turning on jci update via characteristic');
        valueToSave = 1;
      } else {
        log('========Turning off jci update via characteristic');
        valueToSave = 0;
      }
      await characteristic.write(Uint8List.fromList([valueToSave]), false);
      log('========Written \'$valueToSave\' to jci config');
    });
  }

  Future<void> monitorCharacteristicForPeripheral() async {
    await _runWithErrorHandling(() async {
      log('========Start monitoring jci update');
      _startMonitoringJci(
          peripheral
              .monitorCharacteristic(JciServiceUuids.jciServiceUuid,
                  JciServiceUuids.jciDataCharacteristic,
                  transactionId: 'monitor')
              .map((characteristic) => characteristic.value),
          log);
    });
  }

  Future<void> monitorCharacteristicForService() async {
    await _runWithErrorHandling(() async {
      log('========Start monitoring jci update');
      var service = await peripheral.services().then((services) =>
          services.firstWhere((service) =>
              service.uuid == JciServiceUuids.jciServiceUuid.toLowerCase()));
      _startMonitoringJci(
          service
              .monitorCharacteristic(JciServiceUuids.jciDataCharacteristic,
                  transactionId: 'monitor')
              .map((characteristic) => characteristic.value),
          log);
    });
  }

  Future<void> monitorCharacteristic() async {
    await _runWithErrorHandling(() async {
      log('========Start monitoring jci update');
      var service = await peripheral.services().then((services) =>
          services.firstWhere((service) =>
              service.uuid == JciServiceUuids.jciServiceUuid.toLowerCase()));

      var characteristics = await service.characteristics();
      var characteristic = characteristics.firstWhere((characteristic) =>
          characteristic.uuid ==
          JciServiceUuids.jciDataCharacteristic.toLowerCase());

      _startMonitoringJci(
          characteristic.monitor(transactionId: 'monitor'), log);
    });
  }

  Future<void> readWriteMonitorCharacteristicForPeripheral() async {
    await _runWithErrorHandling(() async {
      log('========Test read/write/monitor characteristic on device');
      log('========Start monitoring jci');
      _startMonitoringJci(
        peripheral
            .monitorCharacteristic(JciServiceUuids.jciServiceUuid,
                JciServiceUuids.jciDataCharacteristic,
                transactionId: '1')
            .map((characteristic) => characteristic.value),
        log,
      );
      log('========Turning off jci update');
      await peripheral.writeCharacteristic(
          JciServiceUuids.jciServiceUuid,
          JciServiceUuids.jciConfigCharacteristic,
          Uint8List.fromList([0]),
          false);
      log('========Turned off jci update');

      log('========Waiting one second for the reading');
      await Future.delayed(Duration(seconds: 1));

      log('========Reading jci');
      var readValue = await peripheral.readCharacteristic(
          JciServiceUuids.jciServiceUuid,
          JciServiceUuids.jciDataCharacteristic);
      log('========Read jci value ${_convertToJci(readValue.value)}C');

      log('========Turning on jci update');
      await peripheral.writeCharacteristic(
          JciServiceUuids.jciServiceUuid,
          JciServiceUuids.jciConfigCharacteristic,
          Uint8List.fromList([1]),
          false);

      log('========Turned on jci update');

      log('========Waiting 1 second for the reading');
      await Future.delayed(Duration(seconds: 1));
      log('========Reading jci');
      readValue = await peripheral.readCharacteristic(
          JciServiceUuids.jciServiceUuid,
          JciServiceUuids.jciDataCharacteristic);
      log('========Read jci value ${_convertToJci(readValue.value)}C');

      log('========Canceling jci monitoring');
      await bleManager.cancelTransaction('1');
    });
  }

  Future<void> readWriteMonitorCharacteristicForService() async {
    await _runWithErrorHandling(() async {
      log('========Test read/write/monitor characteristic on service');
      log('========Fetching service');

      var service = await peripheral.services().then((services) =>
          services.firstWhere((service) =>
              service.uuid == JciServiceUuids.jciServiceUuid.toLowerCase()));

      log('========Start monitoring jci');
      _startMonitoringJci(
        service
            .monitorCharacteristic(JciServiceUuids.jciDataCharacteristic,
                transactionId: '2')
            .map((characteristic) => characteristic.value),
        log,
      );

      log('========Turning off jci update');
      await service.writeCharacteristic(
        JciServiceUuids.jciConfigCharacteristic,
        Uint8List.fromList([0]),
        false,
      );
      log('========Turned off jci update');

      log('========Waiting one second for the reading');
      await Future.delayed(Duration(seconds: 1));

      log('========Reading jci value');
      var dataCharacteristic = await service
          .readCharacteristic(JciServiceUuids.jciDataCharacteristic);
      log('========Read jci value ${_convertToJci(dataCharacteristic.value)}C');

      log('========Turning on jci update');
      await service.writeCharacteristic(JciServiceUuids.jciConfigCharacteristic,
          Uint8List.fromList([1]), false);
      log('========Turned on jci update');

      log('========Waiting one second for the reading');
      await Future.delayed(Duration(seconds: 1));

      log('========Reading jci value');
      dataCharacteristic = await service
          .readCharacteristic(JciServiceUuids.jciDataCharacteristic);
      log('========Read jci value ${_convertToJci(dataCharacteristic.value)}C');
      log('========Canceling jci monitoring');
      await bleManager.cancelTransaction('2');
    });
  }

  Future<void> readWriteMonitorCharacteristic() async {
    await _runWithErrorHandling(() async {
      log('========Test read/write/monitor characteristic on characteristic');

      log('========Fetching service');
      var service = await peripheral.services().then((services) =>
          services.firstWhere((service) =>
              service.uuid == JciServiceUuids.jciServiceUuid.toLowerCase()));

      log('========Fetching config characteristic');
      var characteristics = await service.characteristics();
      var configCharacteristic = characteristics.firstWhere((characteristic) =>
          characteristic.uuid ==
          JciServiceUuids.jciConfigCharacteristic.toLowerCase());
      log('========Fetching data characteristic');
      var dataCharacteristic = characteristics.firstWhere((characteristic) =>
          characteristic.uuid ==
          JciServiceUuids.jciDataCharacteristic.toLowerCase());

      log('========Start monitoring jci');
      _startMonitoringJci(
        dataCharacteristic.monitor(transactionId: '3'),
        log,
      );

      log('========Turning off jci update');
      await configCharacteristic.write(Uint8List.fromList([0]), false);
      log('========Turned off jci update');

      log('========Waiting one second for the reading');
      await Future.delayed(Duration(seconds: 1));

      log('========Reading characteristic value');
      var value = await configCharacteristic.read();
      log('========Read jci config value  $value');

      log('========Turning on jci update');
      await configCharacteristic.write(Uint8List.fromList([1]), false);
      log('========Turned on jci update');

      log('========Waiting one second for the reading');
      await Future.delayed(Duration(seconds: 1));

      log('========Reading characteristic value');
      value = await configCharacteristic.read();
      log('========Read jci config value  $value');

      log('========Canceling jci monitoring');
      await bleManager.cancelTransaction('3');
    });
  }

  Future<void> disconnect() async {
    await _runWithErrorHandling(() async {
      log('========WAITING 10 SECOND BEFORE DISCONNECTING');
      await Future.delayed(Duration(seconds: 60));
      log('========DISCONNECTING...');
      await peripheral.disconnectOrCancelConnection();
      log('========Disconnected!========');
    });
  }

  Future<void> fetchConnectedDevice() async {
    await _runWithErrorHandling(() async {
      log('========Fetch connected devices with no service specified');
      var peripherals = await bleManager.connectedPeripherals([]);
      peripherals
          .forEach((peripheral) => log('========\t${peripheral.toString()}'));
      log('========Device fetched');
      log('========Fetch connected devices with jci service');
      peripherals = await bleManager
          .connectedPeripherals([JciServiceUuids.jciServiceUuid]);
      peripherals
          .forEach((peripheral) => log('========\t${peripheral.toString()}'));
      log('========Device fetched');
    });
  }

  Future<void> fetchKnownDevice() async {
    await _runWithErrorHandling(() async {
      log('========Fetch known devices with no IDs specified');
      var peripherals = await bleManager.knownPeripherals([]);
      peripherals
          .forEach((peripheral) => log('========\t${peripheral.toString()}'));
      log('========Device fetched');
      log('========Fetch known devices with one known device\'s ID specified');
      peripherals = await bleManager.knownPeripherals([peripheral.identifier]);
      peripherals
          .forEach((peripheral) => log('========\t${peripheral.toString()}'));
      log('========Device fetched');
    });
  }

  Future<void> readDescriptorForPeripheral() async =>
      _runWithErrorHandling(() async {
        log('========READ DESCRIPTOR FOR PERIPHERAL');
        log('========Reading value...');
        var value = await peripheral
            .readDescriptor(
              JciServiceUuids.jciServiceUuid,
              JciServiceUuids.jciDataCharacteristic,
              JciServiceUuids.clientCharacteristicConfigurationUuid,
            )
            .then((descriptorWithValue) => descriptorWithValue.value);
        log('========Value $value read!========');
      });

  Future<void> readDescriptorForService() async =>
      _runWithErrorHandling(() async {
        log('========READ DESCRIPTOR FOR SERVICE');

        log('========Fetching service');
        var services = await peripheral.services();
        var chosenService = services.firstWhere((elem) =>
            elem.uuid == JciServiceUuids.jciServiceUuid.toLowerCase());

        log('========Reading value...');
        var value = await chosenService
            .readDescriptor(
              JciServiceUuids.jciDataCharacteristic,
              JciServiceUuids.clientCharacteristicConfigurationUuid,
            )
            .then((descriptorWithValue) => descriptorWithValue.value);
        log('========Value $value read!========');
      });

  Future<void> readDescriptorForCharacteristic() async =>
      _runWithErrorHandling(() async {
        log('========READ DESCRIPTOR FOR CHARACTERISTIC');

        log('========Fetching service');
        var services = await peripheral.services();
        var chosenService = services.firstWhere((elem) =>
            elem.uuid == JciServiceUuids.jciServiceUuid.toLowerCase());

        log('========Fetching characteristic');
        var jciCharacteristics = await chosenService.characteristics();
        var chosenCharacteristic = jciCharacteristics.first;

        log('========Reading value...');
        var value = await chosenCharacteristic
            .readDescriptor(
              JciServiceUuids.clientCharacteristicConfigurationUuid,
            )
            .then((descriptorWithValue) => descriptorWithValue.value);
        log('========Value $value read!========');
      });

  Future<void> readDescriptor() async => _runWithErrorHandling(() async {
        log('========READ DESCRIPTOR FOR DESCRIPTOR');

        log('========Fetching service');
        var services = await peripheral.services();
        var chosenService = services.firstWhere((elem) =>
            elem.uuid == JciServiceUuids.jciServiceUuid.toLowerCase());

        log('========Fetching characteristic');
        var jciCharacteristics = await chosenService.characteristics();
        var chosenCharacteristic = jciCharacteristics.first;

        log('========Fetching descriptor');
        var descriptors = await chosenCharacteristic.descriptors();
        var chosenDescriptor = descriptors.firstWhere((elem) =>
            elem.uuid == JciServiceUuids.clientCharacteristicConfigurationUuid);

        log('========Reading value...');
        var value = await chosenDescriptor.read();
        log('========Value $value read!========');
      });

  Future<void> writeDescriptorForPeripheral({bool enable = false}) async =>
      _runWithErrorHandling(() async {
        log('========WRITE DESCRIPTOR FOR PERIPHERAL');
        log('========Writing value...');
        var value = await peripheral.writeDescriptor(
          JciServiceUuids.jciServiceUuid,
          JciServiceUuids.jciDataCharacteristic,
          JciServiceUuids.clientCharacteristicConfigurationUuid,
          Uint8List.fromList([enable ? 1 : 0, 0]),
        );
        log('========Descriptor $value written to!========');
      });

  Future<void> writeDescriptorForService({bool enable = false}) async =>
      _runWithErrorHandling(() async {
        log('========WRITE DESCRIPTOR FOR SERVICE');

        log('========Fetching service');
        var services = await peripheral.services();
        var chosenService = services.firstWhere((elem) =>
            elem.uuid == JciServiceUuids.jciServiceUuid.toLowerCase());

        log('========Writing value...');
        var value = await chosenService.writeDescriptor(
          JciServiceUuids.jciDataCharacteristic,
          JciServiceUuids.clientCharacteristicConfigurationUuid,
          Uint8List.fromList([enable ? 1 : 0, 0]),
        );
        log('========Descriptor $value written to!========');
      });

  Future<void> writeDescriptorForCharacteristic({bool enable = false}) async =>
      _runWithErrorHandling(() async {
        log('========WRITE DESCRIPTOR FOR CHARACTERISTIC');

        log('========Fetching service');
        var services = await peripheral.services();
        var chosenService = services.firstWhere((elem) =>
            elem.uuid == JciServiceUuids.jciServiceUuid.toLowerCase());

        log('========Fetching characteristic');
        var jciCharacteristics = await chosenService.characteristics();
        var chosenCharacteristic = jciCharacteristics.first;

        log('========Writing value...');
        var value = await chosenCharacteristic.writeDescriptor(
          JciServiceUuids.clientCharacteristicConfigurationUuid,
          Uint8List.fromList([enable ? 1 : 0, 0]),
        );
        log('========Descriptor $value written to!========');
      });

  Future<void> writeDescriptor({bool enable = false}) async =>
      _runWithErrorHandling(() async {
        log('========WRITE DESCRIPTOR FOR DESCRIPTOR');

        log('========Fetching service');
        var services = await peripheral.services();
        var chosenService = services.firstWhere((elem) =>
            elem.uuid == JciServiceUuids.jciServiceUuid.toLowerCase());

        log('========Fetching characteristic');
        var jciCharacteristics = await chosenService.characteristics();
        var chosenCharacteristic = jciCharacteristics.first;

        log('========Fetching descriptor');
        var descriptors = await chosenCharacteristic.descriptors();
        var chosenDescriptor = descriptors.firstWhere((elem) =>
            elem.uuid == JciServiceUuids.clientCharacteristicConfigurationUuid);

        log('========Writing value...');
        await chosenDescriptor.write(
          Uint8List.fromList([enable ? 1 : 0, 0]),
        );
        log('========Descriptor $chosenDescriptor written to!========');
      });

  Future<void> readWriteDescriptorForPeripheral() async =>
      _runWithErrorHandling(
        () async {
          log('========READ/WRITE TEST FOR PERIPHERAL');
          await readDescriptorForPeripheral();
          await writeDescriptorForPeripheral(enable: true);
          await readDescriptorForPeripheral();
          await writeDescriptorForPeripheral(enable: false);
          await readDescriptorForPeripheral();
        },
      );

  Future<void> readWriteDescriptorForService() async => _runWithErrorHandling(
        () async {
          log('========READ/WRITE TEST FOR SERVICE');
          await readDescriptorForService();
          await writeDescriptorForService(enable: true);
          await readDescriptorForService();
          await writeDescriptorForService(enable: false);
          await readDescriptorForService();
        },
      );

  Future<void> readWriteDescriptorForCharacteristic() async =>
      _runWithErrorHandling(
        () async {
          log('========READ/WRITE TEST FOR CHARACTERISTIC');
          await readDescriptorForCharacteristic();
          await writeDescriptorForCharacteristic(enable: true);
          await readDescriptorForCharacteristic();
          await writeDescriptorForCharacteristic(enable: false);
          await readDescriptorForCharacteristic();
        },
      );

  Future<void> readWriteDescriptor() async => _runWithErrorHandling(
        () async {
          log('========READ/WRITE TEST FOR DESCRIPTOR');
          await readDescriptor();
          await writeDescriptor(enable: true);
          await readDescriptor();
          await writeDescriptor(enable: false);
          await readDescriptor();
        },
      );

  void _startMonitoringJci(
      Stream<Uint8List> characteristicUpdates, Function log) async {
    await monitoringStreamSubscription?.cancel();
    monitoringStreamSubscription =
        characteristicUpdates.map(_convertToJci).listen(
      (jci) {
        log('========Jci updated: ${jci}C');
      },
      onError: (error) {
        log('========Error while monitoring characteristic  $error');
      },
      cancelOnError: true,
    );
  }

  double _convertToJci(var rawJciBytes) {
    const SCALE_LSB = 0.03125;
    var rawTemp = rawJciBytes[3] << 8 | rawJciBytes[2];
    return ((rawTemp) >> 2) * SCALE_LSB;
  }

  Future<void> disableBluetooth() async {
    await _runWithErrorHandling(() async {
      log('========Disabling radio');
      await bleManager.disableRadio();
    });
  }

  Future<void> enableBluetooth() async {
    await _runWithErrorHandling(() async {
      log('========Enabling radio');
      await bleManager.enableRadio();
    });
  }

  Future<void> fetchBluetoothState() async {
    await _runWithErrorHandling(() async {
      var bluetoothState = await bleManager.bluetoothState();
      log('========Radio state: $bluetoothState');
    });
  }

  Future<void> _runWithErrorHandling(TestedFunction testedFunction) async {
    try {
      await testedFunction();
    } on BleError catch (e) {
      logError('BleError caught: ${e.errorCode.value} ${e.reason}');
    } catch (e) {
      if (e is Error) {
        debugPrintStack(stackTrace: e.stackTrace);
      }
      logError('${e.runtimeType}: $e');
    }
  }
}
