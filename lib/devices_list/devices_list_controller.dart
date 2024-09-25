import 'dart:async';
import 'dart:developer';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:get/get.dart';
import 'package:setup_sensor_app/connected_device/connected_device_view.dart';

class DevicesListController extends GetxController {
  late StreamSubscription<List<ScanResult>> scanResultsSubscription;
  late StreamSubscription<bool> isScanningSubscription;

  List<BluetoothDevice> systemDevices = [];
  List<ScanResult> scanResults = [];
  bool isScanning = false;

  @override
  void onInit() {
    initBluetooth();
    super.onInit();
  }

  @override
  void onClose() {
    scanResultsSubscription.cancel();
    isScanningSubscription.cancel();
    super.onClose();
  }

  initBluetooth() async {
    // Listen to scan results
    scanResultsSubscription = FlutterBluePlus.scanResults.listen((results) {
      log("Received scan results");
      scanResults = results;
      update();
      handleScanResults();
    }, onError: (e) {
      log("Scan Error: $e");
    });

    // Listen to scanning state changes
    isScanningSubscription = FlutterBluePlus.isScanning.listen((state) {
      isScanning = state;
      update();
    });

    // Start scanning immediately
    await startScanning();
  }

  Future<void> startScanning() async {
    log("Starting scanning devices");

    try {
      systemDevices = await FlutterBluePlus.systemDevices;
    } catch (e) {
      log("System Devices Error: $e");
    }

    try {
      // Start scanning for 15 seconds
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 15));
    } catch (e) {
      log("Start Scan Error: $e");
    }
  }

  Future<void> stopScanning() async {
    log("Stopping scanning devices");

    try {
      await FlutterBluePlus.stopScan();
    } catch (e) {
      log("Stop Scan Error: $e");
    }
  }

  void handleScanResults() {
    for (var element in scanResults) {
      log("Name: ${element.device.advName}, ID: ${element.device.id}");

      // Check if the device name matches 'S-Clip'
      if (element.device.advName == 'S-Clip') {
        connectToDevice(element.device);
        break; // Stop scanning after finding 'S-Clip'
      }
    }
  }

  void connectToDevice(BluetoothDevice device) async {
    // log("Connecting to device: ${device.name}");

    try {
      // Connect to the device
      // await device.connect(autoConnect: true);
      // log("Connected to device: ${device.name}");

      // Navigate to ConnectedDeviceView
      await Get.to(() => ConnectedDeviceView(device: device));

      // After returning from ConnectedDeviceView, resume scanning
      await startScanning();
    } catch (e) {
      log("Connection error: $e");

      // Handle disconnection or connection error
      await startScanning();
    }
  }
}
