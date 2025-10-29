import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'sensor_data.dart'; // Your file with SensorData class & sensorDataController
import 'package:just_audio/just_audio.dart';

// Helper class for holding zone information
class HeartRateZone {
  final String name;
  final Color color;
  HeartRateZone(this.name, this.color);
}

class MonitorScreen extends StatefulWidget {
  const MonitorScreen({super.key});

  @override
  State<MonitorScreen> createState() => _MonitorScreenState();
}

class _MonitorScreenState extends State<MonitorScreen> {
  final List<FlSpot> heartbeatData = [];
  double time = 0;

  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isAlarmPlaying = false;

  int _consecutiveDangerousReadings = 0; //monitors number of times in danger heart state

  // 👇 NEW, SMARTER ALARM LOGIC
  Future<void> _manageAlarm(double bpm) async {
    // Define the dangerous BPM thresholds
    const double lowBpmThreshold = 50.0;
    const double highBpmThreshold = 120.0;

    // Define how many consecutive bad readings trigger the alarm
    const int readingsToTriggerAlarm = 3;

    // First, check if the BPM is even a valid reading.
    // We use the same logic as our zone display. If it's below 40,
    // we consider it "measuring" and not a real physiological value.
    if (bpm < 30) {
      // This is a "measuring" or error state. Reset the counter and ensure alarm is off.
      _consecutiveDangerousReadings = 0;
      if (_isAlarmPlaying) {
        print("ALARM: Reading is too low (likely a measurement error). Stopping alarm.");
        await _audioPlayer.stop();
        _isAlarmPlaying = false;
      }
      return; // Exit the function early
    }

    // If we get here, the BPM is > 40, so it's a "real" reading.
    // Now, check if it's in the danger zone.
    bool isDangerous = (bpm < lowBpmThreshold || bpm > highBpmThreshold);

    if (isDangerous) {
      // Increment the counter for each consecutive dangerous reading
      _consecutiveDangerousReadings++;
      print("ALARM_CHECK: Dangerous reading #$_consecutiveDangerousReadings detected (BPM: $bpm).");

      // Check if we've met the threshold to start the alarm
      if (_consecutiveDangerousReadings >= readingsToTriggerAlarm && !_isAlarmPlaying) {
        print("ALARM: Threshold met. Starting alarm.");
        try {
          await _audioPlayer.setAsset('assets/audio/Beep_alarm.mp3');
          _audioPlayer.setLoopMode(LoopMode.one);
          _audioPlayer.play();
          _isAlarmPlaying = true;
        } catch (e) {
          print("Error playing audio: $e");
        }
      }
    } else {
      // The reading is normal. Reset the counter and stop the alarm if it's playing.
      if (_consecutiveDangerousReadings > 0) {
        print("ALARM_CHECK: Normal reading received. Resetting danger counter.");
      }
      _consecutiveDangerousReadings = 0;

      if (_isAlarmPlaying) {
        print("ALARM: BPM is back to normal ($bpm). Stopping alarm.");
        await _audioPlayer.stop();
        _isAlarmPlaying = false;
      }
    }
  }

  // ... your _getHeartRateZone function and build method ...


  // Function to determine the zone from a BPM value
  HeartRateZone _getHeartRateZone(double bpm) {
    if (bpm < 40) return HeartRateZone("Measuring...", Colors.grey);
    if (bpm < 60) return HeartRateZone("Resting", Colors.blueAccent);
    if (bpm < 100) return HeartRateZone("Normal / Active", Colors.green);
    if (bpm < 130) return HeartRateZone("Moderate Intensity", Colors.orangeAccent);
    return HeartRateZone("High Intensity", Colors.red);
  }
  @override
  void dispose() {
    // Release the audio player's resources to prevent memory leaks
    _audioPlayer.dispose();

    // It's crucial to call super.dispose() at the end
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<SensorData>(
      stream: sensorDataController.stream,
      builder: (context, snapshot) {
        // Default values before data arrives
        String currentBpm = "--";
        String currentDistance = "--";
        HeartRateZone zone = _getHeartRateZone(0); // Default to "Measuring..."

        // When new data arrives, update the values
        if (snapshot.hasData) {
          final sensorData = snapshot.data!;

          // Update chart data
          time += 0.1;
          heartbeatData.add(FlSpot(time, sensorData.bpm < 20 ? 0 : sensorData.bpm));
          if (heartbeatData.length > 100) heartbeatData.removeAt(0);

          // Update text display values
          currentBpm = sensorData.bpm.toStringAsFixed(1);
          currentDistance = sensorData.distance.toStringAsFixed(1);

          // =========================================================
          // 👇 THIS IS THE CRITICAL LINE YOU WERE MISSING
          // Get the current zone based on the new BPM
          zone = _getHeartRateZone(sensorData.bpm);

          // Check if the alarm needs to be triggered or stopped
          _manageAlarm(sensorData.bpm);
          // =========================================================
        }

        // Build the UI using the updated 'zone' information
        return Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            title: const Text("Live Monitor"),
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
          ),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Heartbeat Monitor", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 20),

                // =========================================================
                // 👇 THIS IS THE NEW UI WIDGET FOR THE ZONE NAME
                Text(
                  zone.name,
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: zone.color),
                ),
                const SizedBox(height: 10),
                // =========================================================

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.favorite, color: zone.color, size: 28), // Use zone color
                    const SizedBox(width: 8),
                    Text(
                      "$currentBpm bpm",
                      // Make the BPM number itself always white so it's readable
                      style: const TextStyle(fontSize: 20, color: Colors.white70),
                    ),
                  ],
                ),

                SizedBox(
                  height: 200,
                  child: LineChart(
                    LineChartData(
                      minY: 40, maxY: 180,
                      titlesData: FlTitlesData(show: false),
                      gridData: FlGridData(show: false),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: heartbeatData,
                          isCurved: true,
                          color: zone.color, // Use the zone color for the chart line
                          barWidth: 3,
                          dotData: FlDotData(show: false),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 60),

                Text(
                  "Distance: $currentDistance cm",
                  style: const TextStyle(fontSize: 18, color: Colors.white70),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
