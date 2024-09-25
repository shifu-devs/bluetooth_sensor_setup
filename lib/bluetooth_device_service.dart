import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:get/get.dart';

class BluetoothDeviceService extends GetxService {
  @override
  void onInit() {
    Future.delayed(const Duration(seconds: 5), () => initBluetoothListner());
    super.onInit();
  }

  @override
  void onClose() {
    bluetoothAdapterStateListner.cancel();
    isScanningSubscription.cancel();
    scanResultsSubscription.cancel();
    super.onClose();
  }

  @override
  void onReady() {
    super.onReady();
  }

  final gyroStream = StreamController.broadcast();

  static const String S_CLIP_SERVICE_UUID =
      "360c8f5b-40a1-4268-bfe7-f18cbc0ed52b";
  static const String S_CLIP_9DOF_UUID = "30ce2c34-a0cc-48e4-b584-cd70beb9bc36";
  static const String S_CLIP_ACCEL_GYRO_UUID =
      "723e4512-7594-452e-bcd2-f902e9cdb454";
  static const String TEMPERATURE_MEASUREMENT_UUID = "2A1C";
  static const String BATTERY_SERVICE_UUID = "180F";
  static const String BATTERY_LEVEL_SERVICE_UUID = "2A19";

  late StreamSubscription<List<ScanResult>> scanResultsSubscription;
  late StreamSubscription<bool> isScanningSubscription;
  late StreamSubscription<BluetoothAdapterState> bluetoothAdapterStateListner;

  BluetoothAdapterState blueState = BluetoothAdapterState.off;
  bool isScanning = false;
  bool isConnected = false;
  List<ScanResult> allDevices = [];
  bool isRequestingConnection = false;

  initBluetoothListner() async {
    scanResultsSubscription = FlutterBluePlus.scanResults.listen(
      (event) {
        allDevices.clear();
        allDevices.addAll(event);
        filterRequiredDevice();
      },
      onDone: () {
        log("======================> Done call Scan results ");
      },
    );
    bluetoothAdapterStateListner = FlutterBluePlus.adapterState.listen(
      (event) {
        blueState = event;
        if (event == BluetoothAdapterState.unavailable) {
          log("  =====> Bluetooth is Unavailable");
          stopScanningDevices();
        }

        if (event == BluetoothAdapterState.unauthorized) {
          log("  =====> Bluetooth is unauthorized");
          stopScanningDevices();
        }

        if (event == BluetoothAdapterState.off) {
          log("  =====> Bluetooth is Off");
          stopScanningDevices();
          if (Platform.isAndroid) {
            FlutterBluePlus.turnOn();
          }
        }

        if (event == BluetoothAdapterState.on) {
          log("  =====> Bluetooth is on");
          scanDevices();
        }
      },
      onDone: () {
        log("======================> Done call Bluetooth State");
      },
    );
    ////////////////////////
    isScanningSubscription = FlutterBluePlus.isScanning.listen(
      (event) {
        log("=========> Scan event $event");
        isScanning = event;
        if (isScanning == false && isRequestingConnection == false) {
          scanDevices();
        }
      },
      onDone: () {
        log("======================> Done call scanning State");
      },
    );
    ///////////////////////////
  }

  scanDevices() async {
    if (blueState == BluetoothAdapterState.on && isScanning == false) {
      log("==========> scan start");
      gyroStream.sink.add({"is_scanning": true});
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 15));
    }
  }

  stopScanningDevices() async {
    if (isScanning) {
      log("==========> scan Stop");

      await FlutterBluePlus.stopScan();
      gyroStream.sink.add({"is_scanning": false});
    }
  }

  filterRequiredDevice() {
    if (isConnected == false && isRequestingConnection == false) {
      for (var scanResult in allDevices) {
        log("==========> ADV name  => ${scanResult.device.advName} => ${scanResult.device.remoteId.str}");
        if (scanResult.device.advName == 'S-Clip') {
          conectBluetoothDevice(scanResult.device);
          break;
        }
      }
    }
  }

  conectBluetoothDevice(BluetoothDevice device) async {
    if (!device.isConnected) {
      isRequestingConnection = true;
      await stopScanningDevices();
      log("=======> Requesting connection with S-Clip");
      try {
        await device.connect();
        log("=======> Connected with S-Clip");
      } catch (e) {
        log("========= conect exception ==> $e");
        isRequestingConnection = false;
        isConnected = false;
        scanDevices();
        return;
      }

      if (device.isConnected) {
        listenDeviceConnection(device);
        final services = await device.discoverServices();
        log("==========> Service ==> ${services.length}");
        filterRequiredServicesFromSClipSensor(services);
      }
    }
  }

  listenDeviceConnection(BluetoothDevice device) {
    final listenDeviceConnection = device.connectionState.listen(
      (event) {
        if (event == BluetoothConnectionState.connected) {
          log("===========Device Connected ${device.advName}");
          isConnected = true;
          gyroStream.sink.add({"is_connected": true});
        }
        if (event == BluetoothConnectionState.disconnected) {
          log("===========Device Disconnected ${device.advName}");
          gyroStream.sink.add({"is_connected": false});

          isConnected = false;
          isRequestingConnection = false;
          scanDevices();
        }
      },
    );
    device.cancelWhenDisconnected(listenDeviceConnection, delayed: true);
  }

  filterRequiredServicesFromSClipSensor(List<BluetoothService> services) {
    for (BluetoothService service in services) {
      if (service.uuid.toString() == S_CLIP_SERVICE_UUID) {
        for (BluetoothCharacteristic characteristic
            in service.characteristics) {
          if (characteristic.uuid.toString() == S_CLIP_9DOF_UUID) {
            startListeningOnImuCharService(characteristic);
          } else if (characteristic.uuid.toString() == S_CLIP_ACCEL_GYRO_UUID) {
            // startListeningOnAccelGyroCharService(characteristic);
          } else if (characteristic.uuid.toString() ==
              TEMPERATURE_MEASUREMENT_UUID) {
            // startListeningOnTemperatureCharService(characteristic);
          }
        }
      }
      if (service.uuid.toString().toLowerCase() ==
          BATTERY_SERVICE_UUID.toLowerCase()) {
        for (BluetoothCharacteristic characteristic
            in service.characteristics) {
          log("======ch UUID  => ${characteristic.uuid}");

          if (characteristic.uuid.toString().toLowerCase() ==
              BATTERY_LEVEL_SERVICE_UUID.toLowerCase()) {
            startListningBatteryCharService(characteristic);
          }
        }
      }
    }
  }

/////////////////// Battery service ///////////////////

  startListningBatteryCharService(BluetoothCharacteristic battery) async {
    battery.setNotifyValue(true).then((_) {
      battery.onValueReceived.listen(
        (event) {
          if (event.isNotEmpty) {
            gyroStream.sink.add({"battery_percentage": event.first});
          }
        },
      );
    }, onError: (e) {});
    battery.read().then(
      (value) {
        if (value.isNotEmpty) {
          gyroStream.sink.add({"battery_percentage": value.first});
        }
      },
    );
  }

  /////////////// Imu Orientation //////////////////////
  // ImuOrientation? orinetation;
  void startListeningOnImuCharService(BluetoothCharacteristic imuCharService) {
    imuCharService.setNotifyValue(true).then((_) {
      imuCharService.onValueReceived.listen((event) {
        handleImuDataParsing(event);
      });
    }).catchError((e) {
      log('==============> Error enabling notifications: $e');
    });
  }

  handleImuDataParsing(List<int> event) {
    // log("event ===> $event");
    gyroStream.sink.add({"gyro_accel": event});

    // log("Accel_x = ${orinetation!.accel_x.degree} : acel_y= ${orinetation!.accel_y.degree} : acel_z= ${orinetation!.accel_z.degree}");
  }

//////////////////////////////////////////////////////////////////////
  // ImuData? gyroAccel;
  void startListeningOnAccelGyroCharService(
      BluetoothCharacteristic accelGyroCharService) {
    accelGyroCharService.setNotifyValue(true).then((_) {
      accelGyroCharService.onValueReceived.listen((event) {
        handleGyroAccelParsing(event);
      });
    }).catchError((e) {
      log('Error enabling notifications: $e');
    });
  }

  handleGyroAccelParsing(List<int> event) {
    // gyroAccel = ImuData.fromBuffer(Uint8List.fromList(event).buffer);
    gyroStream.sink.add({"gyro_accel": event});
  }

  String axisCounton = "";
  // countingReps() {
  //   if (orinetation != null) {
  //     double x = orinetation!.accel_x.degree;
  //     double y = orinetation!.accel_y.degree;
  //     double z = orinetation!.accel_z.degree;

  //     if ((x > 340 || x < 20) || (z > 340 || z < 20)) {
  //       axisCounton = 'Count on Gyro Y ';
  //     } else if ((y > 340 || y < 20)) {
  //       axisCounton = 'Count on Gyro X ';
  //     } else {
  //       axisCounton = 'Count on Gyro NON ';
  //     }
  //   }
  // }
}
