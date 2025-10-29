import 'package:flutter/material.dart';
import 'package:iot_app/screens/bluetooth_control_screen.dart';
import 'package:iot_app/screens/monitor_screen.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ESP32 Health Monitor',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("ESP32 Health Monitor")),
      body: BluetoothControlScreenWrapper(),
    );
  }
}

// Wrapper to inject the callback into BluetoothControlScreen
class BluetoothControlScreenWrapper extends StatelessWidget {
  const BluetoothControlScreenWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return BluetoothControlScreen();
  }
}


