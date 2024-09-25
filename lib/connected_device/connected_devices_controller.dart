import 'dart:developer';
import 'dart:typed_data';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:get/get.dart';

import 'device_helpers.dart';

class ConnectedDevicesController extends GetxController {
  late BluetoothDevice _device;

  List<BluetoothService> services = [];
  int? rssi;

  // UUIDs for the services and characteristics
  static const String S_CLIP_SERVICE_UUID =
      "360c8f5b-40a1-4268-bfe7-f18cbc0ed52b";
  static const String S_CLIP_9DOF_UUID = "30ce2c34-a0cc-48e4-b584-cd70beb9bc36";
  static const String S_CLIP_ACCEL_GYRO_UUID =
      "723e4512-7594-452e-bcd2-f902e9cdb454";
  static const String TEMPERATURE_MEASUREMENT_UUID = "2A1C";

  List<int> imuCharValues = [];
  List<int> accelGyroValues = [];
  List<int> temperatureValues = [];

  ConnectedDevicesController(BluetoothDevice device) {
    _device = device;
    connectWithDevice();
  }

  @override
  void onReady() {
    super.onReady();
  }

  connectWithDevice() async {
    try {
      await _device.connect(timeout: const Duration(minutes: 1));
      log('===========================>  Starting connecting ===');
      if (!_device.isConnected) {
        return;
      }
      _device.connectionState.listen((event) async {
        if (event == BluetoothConnectionState.connected) {
          log('===========================>  Device connected ===');

          services.clear();
          services.addAll(await _device.discoverServices());
          // rssi ??= await _device.readRssi();
          filterAndListenToServices();
          update();
        }
        if (event == BluetoothConnectionState.disconnected) {
          log('===========================>  Device Disconnected ===');
          Get.back();
        }
      });
    } catch (e) {
      log('===========================> Exception ===> $e');
    }
  }

  void filterAndListenToServices() {
    for (BluetoothService service in services) {
      if (service.uuid.toString() == S_CLIP_SERVICE_UUID) {
        for (BluetoothCharacteristic characteristic
            in service.characteristics) {
          if (characteristic.uuid.toString() == S_CLIP_9DOF_UUID) {
            startListeningOnImuCharService(characteristic);
          } else if (characteristic.uuid.toString() == S_CLIP_ACCEL_GYRO_UUID) {
            startListeningOnAccelGyroCharService(characteristic);
          } else if (characteristic.uuid.toString() ==
              TEMPERATURE_MEASUREMENT_UUID) {
            // startListeningOnTemperatureCharService(characteristic);
          }
        }
      }
    }
  }

////////////////////////////////////////////////////////////////////
  ImuOrientation? orinetation;
  void startListeningOnImuCharService(BluetoothCharacteristic imuCharService) {
    imuCharService.setNotifyValue(true).then((_) {
      imuCharService.value.listen((event) {
        handleImuDataParsing(event);
      });
    }).catchError((e) {
      log('Error enabling notifications: $e');
    });
  }

  handleImuDataParsing(List<int> event) {
    orinetation = ImuOrientation.fromBuffer(Uint8List.fromList(event).buffer);

    update();
  }

//////////////////////////////////////////////////////////////////////
  ImuData? gyroAccel;
  void startListeningOnAccelGyroCharService(
      BluetoothCharacteristic accelGyroCharService) {
    accelGyroCharService.setNotifyValue(true).then((_) {
      accelGyroCharService.value.listen((event) {
        handleGyroAccelParsing(event);
      });
    }).catchError((e) {
      log('Error enabling notifications: $e');
    });
  }

  handleGyroAccelParsing(List<int> event) {
    gyroAccel = ImuData.fromBuffer(Uint8List.fromList(event).buffer);
    update();
  }
//////////////////////////////////////////////////////////////////////

  void startListeningOnTemperatureCharService(
      BluetoothCharacteristic temperatureCharService) {
    temperatureCharService.setNotifyValue(true).then((_) {
      temperatureCharService.value.listen((event) {
        temperatureValues.clear();
        temperatureValues.addAll(event);
        update(['listener']);
        log('==========> Received data from Temperature characteristic: $temperatureValues');
      });
    }).catchError((e) {
      log('Error enabling notifications: $e');
    });
  }

  void readValues(BluetoothCharacteristic charService) async {
    try {
      final dt = await charService.read();
      log('=================== $dt =========>>>>>');
    } catch (e) {
      log('===========Exception ======== $e =========>>>>>');
    }
  }
}

extension DegreeConvertExtension on num {
  String get degree {
    final value = clamp(-1.0, 1.0);

    // Convert the value to degrees
    double degrees = (value * 180.0) + 180.0;

    return degrees.toStringAsFixed(2);
  }
}



///////////////////////////////////////   this code is for jrack
// import 'dart:developer';
// import 'package:flutter/material.dart';
// import 'package:flutter_blue_plus/flutter_blue_plus.dart';
// import 'package:get/get.dart';

// class ConnectedDevicesController extends GetxController {
//   late BluetoothDevice _device;

//   List<BluetoothService> services = [];
//   int? rssi;

//   // UUIDs for the J-Rack services and characteristics
//   static const String BATTERY_SERVICE_UUID = "180F";
//   static const String BATTERY_LEVEL_UUID = "2A19";
//   static const String J_HOOK_SERVICE_UUID = "a9164099-9950-4a8a-8f0e-59dada5e3c63";
//   static const String TEMPERATURE_MEASUREMENT_UUID = "2A1C";
//   static const String HUMIDITY_UUID = "2A6F";
//   static const String ADC_UUID = "a2b330b7-33ec-4f9e-9b23-3bbe55b0796c";

//   List<int> batteryLevelValues = [];
//   List<int> temperatureValues = [];
//   List<int> humidityValues = [];
//   List<int> adcValues = [];

//   ConnectedDevicesController(BluetoothDevice device) {
//     _device = device;
//     connectWithDevice();
//   }

//   @override
//   void onReady() {
//     super.onReady();
//   }

//   connectWithDevice() async {
//     try {
//       await _device.connect();
//       log('===========================>  Starting connecting ===');

//       _device.connectionState.listen((event) async {
//         if (event == BluetoothConnectionState.connected) {
//           log('===========================>  Device connected ===');

//           services.clear();
//           services.addAll(await _device.discoverServices());
//           // rssi ??= await _device.readRssi();
//           filterAndListenToServices();
//           update();
//         }
//         if (event == BluetoothConnectionState.disconnected) {
//           log('===========================>  Device Disconnected ===');

//           services.clear();
//           update();
//         }
//       });
//     } catch (e) {
//       log('===========================> Exception ===> $e');
//     }
//   }

//   void filterAndListenToServices() {
//     for (BluetoothService service in services) {
//       if (service.uuid.toString() == BATTERY_SERVICE_UUID) {
//         for (BluetoothCharacteristic characteristic in service.characteristics) {
//           if (characteristic.uuid.toString() == BATTERY_LEVEL_UUID) {
//             startListeningOnBatteryLevelCharacteristic(characteristic);
//           }
//         }
//       } else if (service.uuid.toString() == J_HOOK_SERVICE_UUID) {
//         for (BluetoothCharacteristic characteristic in service.characteristics) {
//           if (characteristic.uuid.toString() == TEMPERATURE_MEASUREMENT_UUID) {
//             startListeningOnTemperatureCharacteristic(characteristic);
//           } else if (characteristic.uuid.toString() == HUMIDITY_UUID) {
//             startListeningOnHumidityCharacteristic(characteristic);
//           } else if (characteristic.uuid.toString() == ADC_UUID) {
//             startListeningOnAdcCharacteristic(characteristic);
//           }
//         }
//       }
//     }
//     log("================>>>> All fiters work and finished  ===>>>>");
//   }

//   void startListeningOnBatteryLevelCharacteristic(BluetoothCharacteristic characteristic) {
//     characteristic.setNotifyValue(true).then((_) {
//       characteristic.value.listen((event) {
//         batteryLevelValues.clear();
//         batteryLevelValues.addAll(event);
//         update(['listener']);
//         log('==========> Received data from Battery Level characteristic: $batteryLevelValues');
//       });
//     }).catchError((e) {
//       log('Error enabling notifications: $e');
//     });
//   }

//   void startListeningOnTemperatureCharacteristic(BluetoothCharacteristic characteristic) {
//     characteristic.setNotifyValue(true).then((_) {
//       characteristic.value.listen((event) {
//         temperatureValues.clear();
//         temperatureValues.addAll(event);
//         update(['listener']);
//         log('==========> Received data from Temperature characteristic: $temperatureValues');
//       });
//     }).catchError((e) {
//       log('Error enabling notifications: $e');
//     });
//   }

//   void startListeningOnHumidityCharacteristic(BluetoothCharacteristic characteristic) {
//     characteristic.setNotifyValue(true).then((_) {
//       characteristic.value.listen((event) {
//         humidityValues.clear();
//         humidityValues.addAll(event);
//         update(['listener']);
//         log('==========> Received data from Humidity characteristic: $humidityValues');
//       });
//     }).catchError((e) {
//       log('Error enabling notifications: $e');
//     });
//   }

//   void startListeningOnAdcCharacteristic(BluetoothCharacteristic characteristic) async{
//     try{
//   await  characteristic.setNotifyValue(true);

//  characteristic.value.listen((event) {
//         adcValues.clear();
//         adcValues.addAll(event);
//         update(['listener']);
//         log('==========> Received data from ADC characteristic: $adcValues');
//       });
// log( "read values =>>> "+await characteristic.read().toString());
//   }catch(e){
//     log("Exception ======>    $e");
//   }
  
//   }

//   void readValues(BluetoothCharacteristic charService) async {
//     try {
//       final dt = await charService.read();
//       log('=================== $dt =========>>>>>');
//     } catch (e) {
//       log('===========Exception ======== $e =========>>>>>');
//     }
//   }
// }
