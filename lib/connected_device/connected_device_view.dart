import 'package:flutter/material.dart';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:get/get.dart';
import 'package:setup_sensor_app/connected_device/connected_devices_controller.dart';

// ignore: must_be_immutable
class ConnectedDeviceView extends StatelessWidget {
  BluetoothDevice device;
  ConnectedDeviceView({required this.device, super.key});
  @override
  Widget build(BuildContext context) {
    return GetBuilder<ConnectedDevicesController>(
        init: ConnectedDevicesController(device),
        builder: (controller) {
          return Scaffold(
            appBar: AppBar(
              title: const Text(" Device Event Screent"),
            ),
            body: Container(
              margin: const EdgeInsets.all(15),
              child: controller.orinetation != null &&
                      controller.gyroAccel != null
                  ? SingleChildScrollView(
                      child: Column(
                        children: [
                          const Text(
                            'Orinetation',
                            style: TextStyle(fontSize: 25),
                          ),
                          const SizedBox(
                            height: 20,
                          ),
                          smallWidget(
                            "axel_x",
                            controller.orinetation!.accel_x.degree,
                          ),
                          smallWidget(
                              "axel_y", controller.orinetation!.accel_y.degree),
                          smallWidget(
                              "axel_z", controller.orinetation!.accel_z.degree),
                          const SizedBox(
                            height: 10,
                          ),
                          smallWidget(
                              "quat_x",
                              controller.orinetation!.quat_x
                                  .toStringAsFixed(2)),
                          smallWidget(
                              "quat_y",
                              controller.orinetation!.quat_y
                                  .toStringAsFixed(2)),
                          smallWidget(
                              "quat_z",
                              controller.orinetation!.quat_z
                                  .toStringAsFixed(2)),
                          smallWidget(
                              "quat_w",
                              controller.orinetation!.quat_w
                                  .toStringAsFixed(2)),
                          const SizedBox(
                            height: 50,
                          ),
                          const Text(
                            'Motion',
                            style: TextStyle(fontSize: 25),
                          ),
                          const SizedBox(
                            height: 20,
                          ),
                          smallWidget("axel_x",
                              controller.gyroAccel!.accel_x.toStringAsFixed(2)),
                          smallWidget("axel_y",
                              controller.gyroAccel!.accel_y.toStringAsFixed(2)),
                          smallWidget("axel_z",
                              controller.gyroAccel!.accel_z.toStringAsFixed(2)),
                          const SizedBox(
                            height: 10,
                          ),
                          smallWidget("gyro_x",
                              controller.gyroAccel!.gyro_x.toStringAsFixed(2)),
                          smallWidget("gyro_y",
                              controller.gyroAccel!.gyro_y.toStringAsFixed(2)),
                          smallWidget("gyro_z",
                              controller.gyroAccel!.gyro_z.toStringAsFixed(2)),
                        ],
                      ),
                    )
                  : const SizedBox(),
            ),
          );
        });
  }

  Widget smallWidget(String v1, String v2) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          v1,
          style: const TextStyle(fontSize: 18),
        ),
        Text(
          v2,
          style: const TextStyle(fontSize: 18),
        ),
      ],
    );
  }
}
