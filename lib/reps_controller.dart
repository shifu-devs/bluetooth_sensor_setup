import 'dart:developer';
import 'dart:typed_data';

import 'package:get/get.dart';
import 'package:setup_sensor_app/bluetooth_device_service.dart';
import 'package:setup_sensor_app/connected_device/device_helpers.dart';

class RepsController extends GetxController {
  bool isSensorConnected = false;
  bool isScanning = true;
  int batteryPercentage = -1;
  ImuOrientation? gyroAccel;

  @override
  void onReady() {
    listenSensorServiceStream();
    super.onReady();
  }

  final sensorService = Get.find<BluetoothDeviceService>();

  listenSensorServiceStream() {
    sensorService.sensorStream.stream.listen((event) {
      handleStreamevent(event);
    });
  }

  handleStreamevent(event) {
    isSensorConnected = event['is_connected'] ?? isSensorConnected;
    isScanning = event['is_scanning'] ?? isScanning;
    batteryPercentage = event['battery_percentage'] ?? batteryPercentage;

    if (event['gyro_accel'] != null) {
      if (event['gyro_accel'] is List<int>) {
        handleGyroValues(event['gyro_accel']);
      }
    }
  }

  handleGyroValues(List<int> event) {
    gyroAccel = ImuOrientation.fromBuffer(Uint8List.fromList(event).buffer);

    gyroXList.add(gyroAccel!.accel_x.addingThreshold.toDouble());
    gyroYList.add(gyroAccel!.accel_y.addingThreshold.toDouble());
    gyroZList.add(gyroAccel!.accel_z.addingThreshold.toDouble());
    // sumGyroList.add((gyroXList.last + gyroYList.last + gyroZList.last) / 3);
    if (gyroXList.length > 300) {
      gyroXList.removeAt(0);
      gyroYList.removeAt(0);
      gyroZList.removeAt(0);
    }
    // if (gyroYList.length == 1000) {
    //   log("Gyro_Y_List_Real_data $gyroYList");
    //   gyroYList.clear();
    // }
    // countRepsAlgo(gyroAccel!);
    update();
  }

  ////////////////////////////////////////////   Reps Counting Logic ////////////////////
  DateTime lastEvent = DateTime.now();
  List<double> liftUpList = [];
  List<double> dropList = [];
  List<double> gyroXList = [];
  List<double> gyroYList = [];
  List<double> gyroZList = [];
  List<double> sumGyroList = [];
  bool switchList = true;
  int delayInResetValue = 700; // delay iin ms

  int difference = 0;
  int reps = 0;
  // countRepsAlgo(ImuData gyro) {
  //   double sumGyro = gyro.gyro_y.addingThreshold.toDouble();

  //   if (sumGyro == 0) {
  //     final elapsedTime = DateTime.now().difference(lastEvent);
  //     if (elapsedTime.inSeconds > 3) {
  //       liftUpList.clear();
  //       dropList.clear();
  //       switchList = true;
  //     }
  //     if (elapsedTime.inMilliseconds < 1000) {
  //       switchList = !switchList;
  //       if (liftUpList.isNotEmpty && dropList.isNotEmpty) {
  //         if (liftUpList.length > 20 && dropList.length > 20) {
  //           caculateReps();
  //         } else {

  //           lastEvent = DateTime.now();
  //           liftUpList.clear();
  //           dropList
  //               .clear(); //// write here ormula to find which =values in which list and its length
  //         }
  //       }
  //     }
  //   } else {
  //     lastEvent = DateTime.now();
  //     // final elapsedTime = DateTime.now().difference(lastEvent);
  //     if (switchList) {
  //       liftUpList.add(sumGyro);
  //     } else {
  //       dropList.add(sumGyro);
  //     }
  //   }
  // }
  List<double> last50Index = [];
  bool isNegativeHalf = false;
  bool isPositiveHalf = false;
  countRepsAlgo(ImuData gyro) {
    double y = gyro.gyro_y.addingThreshold.toDouble();
    last50Index.add(y);
    if (last50Index.length == 50) {
      final calculationConsecutive = maxConsecutiveValuesLength(last50Index);
      int zeros = calculationConsecutive['zero'] ?? 0;
      int negatives = calculationConsecutive['negative'] ?? 0;
      int positives = calculationConsecutive['positive'] ?? 0;
      log("Zeros ====>>> $zeros");
      log("Positives ====>>> $positives");
      log("Negatives ====>>> $negatives");

      if (zeros >= (negatives + positives)) {
        last50Index.clear();
        isPositiveHalf = false;
        isNegativeHalf = false;
        lastEvent = DateTime.now();
      } else if (negatives >= 15 && positives >= 15) {
        isPositiveHalf = false;
        isNegativeHalf = false;
        increaseRep();
      } else if (negatives >= (positives + zeros)) {
        if (isPositiveHalf) {
          isPositiveHalf = false;
          isNegativeHalf = false;
          increaseRep();
        } else {
          isNegativeHalf = true;
        }
      } else if (positives >= (negatives + zeros)) {
        if (isNegativeHalf) {
          isPositiveHalf = false;
          isNegativeHalf = false;
          increaseRep();
        } else {
          isPositiveHalf = true;
        }
      } else if (zeros >= negatives && zeros >= positives) {
        if ((negatives + positives) > 25) {
          if (negatives >= positives) {
            if (isPositiveHalf) {
              isPositiveHalf = false;
              isNegativeHalf = false;
              increaseRep();
            } else {
              isNegativeHalf = true;
            }
          } else {
            if (isNegativeHalf) {
              isPositiveHalf = false;
              isNegativeHalf = false;
              increaseRep();
            } else {
              isPositiveHalf = true;
            }
          }
        } else {
          last50Index.clear();
          isPositiveHalf = false;
          isNegativeHalf = false;
          lastEvent = DateTime.now();
        }
      } else if (negatives > positives) {
        if (isPositiveHalf) {
          isPositiveHalf = false;
          isNegativeHalf = false;
          increaseRep();
        } else {
          isNegativeHalf = true;
        }
      } else if (positives > negatives) {
        if (isNegativeHalf) {
          isPositiveHalf = false;
          isNegativeHalf = false;
          increaseRep();
        } else {
          isPositiveHalf = true;
        }
      }
    }
  }

  increaseRep() {
    reps++;
    last50Index.clear();
    lastEvent = DateTime.now();
  }

  Map<String, int> maxConsecutiveValuesLength(List<double> values) {
    int maxNegative = 0;
    int maxPositive = 0;
    int maxZero = 0;

    int currentNegative = 0;
    int currentPositive = 0;
    int currentZero = 0;

    for (int i = 0; i < values.length; i++) {
      if (values[i] < 0) {
        // Count consecutive negative values
        currentNegative++;
        // Check if it's a new max length
        if (currentNegative > maxNegative) {
          maxNegative = currentNegative;
        }
        // Reset other counters
        currentPositive = 0;
        currentZero = 0;
      } else if (values[i] > 0) {
        // Count consecutive positive values
        currentPositive++;
        // Check if it's a new max length
        if (currentPositive > maxPositive) {
          maxPositive = currentPositive;
        }
        // Reset other counters
        currentNegative = 0;
        currentZero = 0;
      } else {
        // Count consecutive zero values
        currentZero++;
        // Check if it's a new max length
        if (currentZero > maxZero) {
          maxZero = currentZero;
        }
        // Reset other counters
        currentNegative = 0;
        currentPositive = 0;
      }
    }

    return {
      'negative': maxNegative,
      'positive': maxPositive,
      'zero': maxZero,
    };
  }

  caculateReps() {
    final sumLiftUp =
        liftUpList.reduce((value, element) => (value + element) / 3);
    final sumDrop = dropList.reduce((value, element) => (value + element) / 3);
    difference = sumLiftUp.compareTo(sumDrop);
    if (difference.isNegative) {
      difference * -1;
    }
    if (difference < 5) {
      reps++;
    }
    liftUpList.clear();
    dropList.clear();
  }
}

extension DegreeConvertExtension on num {
  double get degree {
    final value = clamp(-1.0, 1.0);

    // Convert the value to degrees
    double degrees = (value * 180.0) + 180.0;

    return double.parse(degrees.toStringAsFixed(2));
  }

  double get addingThreshold {
    double threshold = 0.5;
    var v = this;
    if (v.isNegative) {
      if (v < -threshold) {
        return v.toDouble();
      }
    }
    if (!v.isNegative) {
      if (v > threshold) {
        return v.toDouble();
      }
    }

    if (v > threshold) {
      return v.toDouble() - threshold;
    }
    return 0.0;
  }
}
