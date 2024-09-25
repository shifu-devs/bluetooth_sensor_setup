import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:setup_sensor_app/reps_controller.dart';
import 'package:chart_sparkline/chart_sparkline.dart';

class DevicesListView extends StatelessWidget {
  const DevicesListView({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<RepsController>(
        init: RepsController(),
        builder: (controller) {
          return Scaffold(
            appBar: AppBar(
              title: const Text("Devices List Results"),
            ),
            body: SizedBox(
                child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(
                      'Is Scanning  = ${controller.isScanning}',
                      style: const TextStyle(fontSize: 25),
                    ),
                    Text(
                      'Is Connected  = ${controller.isSensorConnected}',
                      style: const TextStyle(fontSize: 25),
                    ),
                    controller.gyroAccel != null
                        ? Column(
                            children: [
                              Text(
                                'Battery % = ${controller.batteryPercentage}',
                                style: const TextStyle(fontSize: 25),
                              ),

                              const Text(
                                'Orinetation',
                                style: TextStyle(fontSize: 25),
                              ),
                              const SizedBox(
                                height: 20,
                              ),
                              smallWidget(
                                "axel_x",
                                controller.gyroAccel!.accel_x.degree
                                    .toDouble()
                                    .toStringAsFixed(2),
                              ),
                              smallWidget(
                                  "axel_y",
                                  controller.gyroAccel!.accel_y.degree
                                      .toDouble()
                                      .toStringAsFixed(2)),
                              smallWidget(
                                  "axel_z",
                                  controller.gyroAccel!.accel_z.degree
                                      .toDouble()
                                      .toStringAsFixed(2)),
                              const SizedBox(
                                height: 10,
                              ),

                              // const Text(
                              //   "Motion",
                              //   style: TextStyle(fontSize: 25),
                              // ),

                              // const SizedBox(
                              //   height: 10,
                              // ),
                              // smallWidget(
                              //     "gyro_x",
                              //     controller.gyroAccel!.gyro_x.addingThreshold
                              //         .toStringAsFixed(2)),
                              // smallWidget(
                              //     "gyro_y",
                              //     controller.gyroAccel!.gyro_y.addingThreshold
                              //         .toStringAsFixed(2)),
                              // smallWidget(
                              //     "gyro_z",
                              //     controller.gyroAccel!.gyro_z.addingThreshold
                              //         .toStringAsFixed(2)),
                              const SizedBox(
                                height: 10,
                              ),
                              Text(
                                "Diierence = ${controller.difference} || Reps = ${controller.reps}",
                                style: const TextStyle(fontSize: 25),
                              ),
                              const Text(
                                "Gyro X",
                                style: TextStyle(fontSize: 25),
                              ),
                              graphWidget(context, controller.gyroXList),
                              const Text(
                                "Gyro Y",
                                style: TextStyle(fontSize: 25),
                              ),
                              graphWidget(context, controller.gyroYList),
                              const Text(
                                "Gyro Z",
                                style: TextStyle(fontSize: 25),
                              ),
                              graphWidget(context, controller.gyroZList),
                              const Text(
                                "Sum Gyro ",
                                style: TextStyle(fontSize: 25),
                              ),
                              graphWidget(context, (controller.gyroZList)),

                              // smallWidget(
                              //     "Everage Values",
                              //     ((controller.gyroAccel!.gyro_x.mutiply100 +
                              //                 controller.gyroAccel!.gyro_y
                              //                     .mutiply100 +
                              //                 controller.gyroAccel!.gyro_z
                              //                     .mutiply100) /
                              //             3)
                              //         .toStringAsFixed(2)),
                              // smallWidget(
                              //     "Sum Values",
                              //     ((controller.gyroAccel!.gyro_x.mutiply100 +
                              //             controller
                              //                 .gyroAccel!.gyro_y.mutiply100 +
                              //             controller
                              //                 .gyroAccel!.gyro_z.mutiply100))
                              //         .toStringAsFixed(2)),
                            ],
                          )
                        : const SizedBox(),
                  ],
                ),
              ),
            )),
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

  Widget graphWidget(BuildContext context, List<double> data) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.22,
        width: MediaQuery.of(context).size.width,
        child: Sparkline(
          data: data,
          pointsMode: PointsMode.all,
          pointColor: Colors.red,
          lineColor: Colors.green,
          enableGridLines: true,
          max: 4,
          min: -4,
        ),
      ),
    );
  }
}
