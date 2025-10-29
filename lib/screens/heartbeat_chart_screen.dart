import 'dart:async';
import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class HeartbeatChartScreen extends StatefulWidget {
  const HeartbeatChartScreen({super.key});

  @override
  State<HeartbeatChartScreen> createState() => _HeartbeatChartScreenState();
}

class _HeartbeatChartScreenState extends State<HeartbeatChartScreen>
    with SingleTickerProviderStateMixin {
  final List<FlSpot> _points = [];
  double _xValue = 0;
  Timer? _timer;
  final Random _random = Random();

  late AnimationController _heartController;
  late Animation<double> _scaleAnimation;
  double _currentBpm = 75;

  @override
  void initState() {
    super.initState();

    // Animation controller for beating heart
    _heartController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2)
        .chain(CurveTween(curve: Curves.easeInOut))
        .animate(_heartController);

    _startSimulation();
  }

  void _startSimulation() {
    _timer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      setState(() {
        double yValue;
        if (_xValue % 30 == 0) {
          // Big spike (heartbeat)
          yValue = 90 + _random.nextDouble() * 10;
          _currentBpm = (60 + _random.nextInt(40)) as double;
          _heartController.forward(from: 0.0); // safe restart
        } else if (_xValue % 30 == 2) {
          yValue = 40 + _random.nextDouble() * 5;
        } else {
          yValue = 60 + _random.nextDouble() * 5;
        }

        _points.add(FlSpot(_xValue, yValue));
        _xValue += 1;
        if (_points.length > 60) _points.removeAt(0);
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _heartController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Heartbeat Monitor"),
        backgroundColor: Colors.black,
        foregroundColor: Colors.greenAccent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),

            // Animated Heart + BPM display
            ScaleTransition(
              scale: _scaleAnimation,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.favorite,
                      color: Colors.redAccent, size: 50),
                  const SizedBox(width: 10),
                  Text(
                    "${_currentBpm.toStringAsFixed(0)} BPM",
                    style: const TextStyle(
                      color: Colors.greenAccent,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ECG Graph
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: LineChart(
                  LineChartData(
                    minY: 30,
                    maxY: 110,
                    titlesData: const FlTitlesData(show: false),
                    gridData: FlGridData(
                      show: true,
                      getDrawingHorizontalLine: (_) => FlLine(
                        color: Colors.green.withOpacity(0.2),
                        strokeWidth: 0.5,
                      ),
                      getDrawingVerticalLine: (_) => FlLine(
                        color: Colors.green.withOpacity(0.2),
                        strokeWidth: 0.5,
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: _points,
                        isCurved: true,
                        color: Colors.greenAccent,
                        barWidth: 3,
                        isStrokeCapRound: true,
                        belowBarData: BarAreaData(
                          show: true,
                          color: Colors.greenAccent.withOpacity(0.05),
                        ),
                        dotData: const FlDotData(show: false),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
