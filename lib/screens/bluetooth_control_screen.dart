import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'monitor_screen.dart';
import 'sensor_data.dart'; // Ensure this file is available

class BluetoothControlScreen extends StatefulWidget {

  const BluetoothControlScreen({super.key});


  @override
  State<BluetoothControlScreen> createState() => _BluetoothControlScreenState();
}

class _BluetoothControlScreenState extends State<BluetoothControlScreen> {
  final FlutterBluePlus flutterBlue = FlutterBluePlus();
  List<ScanResult> scanResults = [];
  BluetoothDevice? connectedDevice;
  bool isScanning = false;
  bool sensorsOn = false; // unified toggle
  bool isReady = false;

  StreamSubscription<List<ScanResult>>? scanSubscription;
  BluetoothCharacteristic? dataChar;    // for notifications
  BluetoothCharacteristic? commandChar; // for sending commands
  StreamSubscription<List<int>>? dataSubscription;

  @override
  void initState() {
    super.initState();
    requestPermissions();
  }

  Future<void> requestPermissions() async {
    await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();
  }

  void startScan() async {
    setState(() {
      scanResults.clear();
      isScanning = true;
    });

    FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));

    scanSubscription = FlutterBluePlus.scanResults.listen((results) {
      setState(() {
        scanResults = results;
      });
    });

    FlutterBluePlus.isScanning.listen((scanning) {
      if (!scanning) setState(() => isScanning = false);
    });
  }

  void stopScan() {
    FlutterBluePlus.stopScan();
    scanSubscription?.cancel();
    setState(() => isScanning = false);
  }

  // Corrected connectToDevice function
// ===============================================================
// FINAL, MORE FLEXIBLE connectToDevice FUNCTION
// ===============================================================
  void connectToDevice(BluetoothDevice device) async {
    // Make sure the UI knows we are not ready yet
    setState(() {
      isReady = false;
    });

    stopScan();
    try {
      await device.connect(timeout: const Duration(seconds: 15));
      setState(() => connectedDevice = device);

      // Listen for disconnection
      device.connectionState.listen((BluetoothConnectionState state) async {
        if (state == BluetoothConnectionState.disconnected) {
          setState(() {
            connectedDevice = null;
            isReady = false; // <-- SET TO FALSE ON DISCONNECT
            sensorsOn = false; // Reset the switch UI
          });
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Device Disconnected")));
        }
      });

      List<BluetoothService> services = await device.discoverServices();
      // ... (the discovery logic is the same and correct)
      const String shortServiceUuid = "00ff";
      const String shortCharUuid = "ff01";
      var targetService = services.firstWhere(
            (s) => s.uuid.toString().contains(shortServiceUuid),
        orElse: () => throw "Target Service (containing '$shortServiceUuid') Not Found.",
      );
      var characteristic = targetService.characteristics.firstWhere(
            (c) => c.uuid.toString().contains(shortCharUuid),
        orElse: () => throw "Target Characteristic (containing '$shortCharUuid') Not Found.",
      );
      dataChar = characteristic;
      commandChar = characteristic;

      // This is the ASYNCHRONOUS part. We must wait for it.
      await dataChar!.setNotifyValue(true);

      // Find this part in your connectToDevice function
      dataSubscription = dataChar!.value.listen((data) {
        // ... your old parsing logic ...
      });

// And replace it with this:

// ===============================================================
// FINAL, ROBUST DATA PARSING LOGIC
// ===============================================================
      dataSubscription = dataChar!.value.listen((data) {
        // 1. Make sure we have data
        if (data.isEmpty) {
          return;
        }

        // 2. Convert the data to a string
        String received = utf8.decode(data, allowMalformed: true).trim();
        print("Received raw data: '$received'");

        // 3. Check if the data packet looks valid before trying to parse it
        if (received.contains("BPM:") && received.contains("DIST:")) {
          try {
            double bpm = 0;
            double distance = 0;
            final parts = received.split(';');

            for (var part in parts) {
              if (part.startsWith('BPM:')) {
                bpm = double.tryParse(part.substring(4)) ?? 0.0;
              }
              if (part.startsWith('DIST:')) {
                distance = double.tryParse(part.substring(5)) ?? 0.0;
              }
            }

            // 4. If parsing is successful, add it to the stream
            print("Successfully parsed -> BPM: $bpm, DIST: $distance. Adding to stream.");
            sensorDataController.add(SensorData(bpm: bpm, distance: distance));

          } catch (e) {
            // This catch block will now only catch truly unexpected errors
            print("Error during parsing: $e");
          }
        } else {
          // This will tell us if we are receiving incomplete packets
          print("Skipping malformed/incomplete packet: '$received'");
        }
      });


      // --- THIS IS THE CRITICAL CHANGE ---
      // Only after everything above has succeeded, we are ready.
      setState(() {
        isReady = true; // <-- SET TO TRUE WHEN READY
      });
      // ------------------------------------

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      await connectedDevice?.disconnect();
      setState(() {
        isReady = false; // <-- SET TO FALSE ON FAILURE
      });
    }
  }





  // Sends command to ESP32 (now uses commandChar)
  // Corrected sendCommand function
  void sendCommand(String cmd) async {
    if (commandChar == null) {
      print("Command characteristic not found!");
      return;
    }
    try {
      // Use write() to send the command
      await commandChar!.write(utf8.encode(cmd), withoutResponse: false);
      print("Sent command: $cmd");
    } catch (e) {
      print("Failed to send command: $e");
    }
  }


  @override
  void dispose() {
    stopScan();
    dataSubscription?.cancel();
    connectedDevice?.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          children: [
            const Text(
              "Bluetooth Control",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: isScanning ? null : startScan,
              icon: const Icon(Icons.search),
              label: Text(isScanning ? "Scanning..." : "Scan for Devices"),
            ),
            const SizedBox(height: 10),
            ...scanResults.map((result) => Card(
              child: ListTile(
                title: Text(result.device.name.isNotEmpty
                    ? result.device.name
                    : "Unknown Device"),
                subtitle: Text(result.device.id.toString()),
                trailing: ElevatedButton(
                  onPressed: () => connectToDevice(result.device),
                  child: const Text("Connect"),
                ),
              ),
            )),
            const Divider(height: 30),
            const Text(
              "Sensor Control",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            // 👇 Single toggle for both sensors
            Column(
              children: [
                const Text("All Sensors"),
                // NEW, CORRECTED Switch logic
                // FINAL, CORRECTED Switch
                Switch(
                  value: sensorsOn,
                  // Disable the switch if we are not connected and ready
                  onChanged: (connectedDevice != null && isReady)
                      ? (val) {
                    setState(() => sensorsOn = val);
                    sendCommand(val ? "SENSORS_ON" : "SENSORS_OFF");
                  }
                      : null, // Set onChanged to null to disable it
                ),


              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const MonitorScreen()),
                );
              },
              child: const Text("Go to Monitor"),
            ),
          ],
        ),
      ),
    );
  }
}
