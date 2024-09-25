import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:setup_sensor_app/bluetooth_device_service.dart';
import 'package:setup_sensor_app/devices_list/devices_list.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Flutter Demo',
      initialBinding:
          BindingsBuilder.put(() => BluetoothDeviceService(), permanent: true),
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const DevicesListView(),
    );
  }
}
