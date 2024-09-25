import 'dart:core';
import 'dart:typed_data';

// SClip acceleration | gyro | timestamp
class ImuData {
  num accel_x = 0;
  num accel_y = 0;
  num accel_z = 0;

  num gyro_x = 0;
  num gyro_y = 0;
  num gyro_z = 0;

  num timestamp = 0;

  // These constants are also set in the SClip device firmware
  static final double accel_range = 4; // Acceleration range - 0-4g
  static final double gyro_range = 2000; // Gyro range - 2000dps

  ImuData.fromBuffer(ByteBuffer buffer) {
    var data = buffer.asByteData();

    this.accel_x = data.getInt16(0, Endian.little);
    this.accel_y = data.getInt16(2, Endian.little);
    this.accel_z = data.getInt16(4, Endian.little);

    this.gyro_x = data.getInt16(6, Endian.little);
    this.gyro_y = data.getInt16(8, Endian.little);
    this.gyro_z = data.getInt16(10, Endian.little);

    this.timestamp = data.getUint32(18, Endian.little);

    // scale raw value to actual readings
    this.accel_x = (this.accel_x / (1<<15)) * accel_range;
    this.accel_y = (this.accel_y / (1<<15)) * accel_range;
    this.accel_z = (this.accel_z / (1<<15)) * accel_range;

    this.gyro_x = (this.gyro_x / (1<<15)) * gyro_range;
    this.gyro_y = (this.gyro_y / (1<<15)) * gyro_range;
    this.gyro_z = (this.gyro_z / (1<<15)) * gyro_range;
  }
}

// SClip 9DoF quaternion | acceleration | timestamp
class ImuOrientation {
  double quat_x = 0;
  double quat_y = 0;
  double quat_z = 0;
  double quat_w = 0;

  num timestamp = 0;

  num accel_x = 0;
  num accel_y = 0;
  num accel_z = 0;

  ImuOrientation.fromBuffer(ByteBuffer buffer) {
    var data = buffer.asByteData();

    this.quat_x = data.getFloat64(0, Endian.little);
    this.quat_y = data.getFloat64(8, Endian.little);
    this.quat_z = data.getFloat64(16, Endian.little);
    this.quat_w = data.getFloat64(24, Endian.little);

    this.timestamp = data.getUint32(32, Endian.little);

    this.accel_x = data.getInt16(36, Endian.little);
    this.accel_y = data.getInt16(38, Endian.little);
    this.accel_z = data.getInt16(40, Endian.little);

    // scale accel raw value to actual readings
    this.accel_x = (this.accel_x / (1<<15)) * ImuData.accel_range;
    this.accel_y = (this.accel_y / (1<<15)) * ImuData.accel_range;
    this.accel_z = (this.accel_z / (1<<15)) * ImuData.accel_range;
  }
}

// JRack voltage | weight
class JRackData {
  // ADC voltage in volts
  num voltage_1 = 0;
  num voltage_2 = 0;

  num weight_1 = 0;
  num weight_2 = 0;

  // These constants are also set in the JRack device firmware
  static final num vref = 2.4; // ADC Reference voltage
  static final num gain = 64; // ADC Gain

  // How much milivolts per kG (it's not 1:1, this is just for example).
  // We cannot say exact value, it differs a lot on every sensor manufacturer.
  // You could move this out of this class and pass as variable to
  // the fromBuffer method.
  static final num weight_to_voltage_ratio = 1.0;

  JRackData.fromBuffer(ByteBuffer buffer) {
    var data = buffer.asByteData();

    this.voltage_1 = data.getInt32(0, Endian.little);
    this.voltage_2 = data.getInt32(4, Endian.little);

    // convert to voltage
    this.voltage_1 = (this.voltage_1 / (1 << 23)) * vref / gain;
    this.voltage_2 = (this.voltage_2 / (1 << 23)) * vref / gain;

    // convert to actual weight in kilograms
    this.weight_1 = this.voltage_1 * weight_to_voltage_ratio;
    this.weight_2 = this.voltage_2 * weight_to_voltage_ratio;
  }
}

/*
Example usage:

// Pass buffer from BLE characteristic notification
// bufferFromBle = [12, 24, 255, 0, 255, 255.... w/e]

ImuData d = new ImuData.fromBuffer(bufferFromBle);
print(d.accel_x); // prints acceleration X value

ImuOrientation orient = new ImuOrientation.fromBuffer(bufferFromBle);
print(d.quat_x); // prints quaternion X value

JRackData rack = new JRackData.fromBuffer(bufferFromBle);
print(rack.voltage_1); // prints voltage on channel 1 (in volts)
print(rack.weight_1); // prints weight on channel 1 (in kilograms)
print(rack.weight_1 + rack.weight_2); // prints total rack weight

*/

int main(List<String> args) {
    print('testing parsing');
    var b = [186, 254, 216, 0, 54, 32, 7, 8, 9, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 0, 1, 2];
    ImuData d = new ImuData.fromBuffer(Uint8List.fromList(b).buffer);
    print('ImuData -> accel x=${d.accel_x} y=${d.accel_y} z=${d.accel_z}');


    b = [83, 89, 215, 106, 229, 247, 239, 63, 0, 0, 0, 128, 171, 136, 136, 63, 0, 0, 0, 64, 178, 41, 146, 63, 0, 0, 0, 40, 23, 245, 163, 63, 246, 30, 81, 4, 186, 254, 216, 0, 54, 32];
    ImuOrientation orient = new ImuOrientation.fromBuffer(Uint8List.fromList(b).buffer);
    print('quaternion ${orient.quat_x} ${orient.quat_y} ${orient.quat_z} ${orient.quat_w}');
    print('accel x=${orient.accel_x} y=${orient.accel_y} z=${orient.accel_z}');
    print('timestamp ${orient.timestamp} ms');
    return 0;
}
