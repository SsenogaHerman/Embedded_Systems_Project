import 'dart:async';
import 'dart:ui';

import '../models/heartrate_zone.dart';

// Class to hold your sensor readings
class SensorData {
  final double bpm;      // Heartbeat in BPM
  final double distance; // Ultrasonic distance in cm
  SensorData({required this.bpm, required this.distance});



}

// StreamController to broadcast sensor updates
final StreamController<SensorData> sensorDataController =
StreamController<SensorData>.broadcast();

