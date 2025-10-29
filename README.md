
# ESP32 Health Monitoring System


## 📋 Project Overview

This project is an innovative, real-time health monitoring system that leverages an ESP32 microcontroller and a Flutter mobile application. It captures live physiological data from hardware sensors, transmits it wirelessly via Bluetooth Low Energy (BLE), and displays it on a user-friendly mobile interface with intelligent alerts.

The system is designed to be a comprehensive, low-cost solution for monitoring key health metrics, making it suitable for personal wellness tracking, fitness applications, or as a proof-of-concept for remote patient monitoring.

This project was developed as a demonstration of skills in embedded systems programming, mobile app development, and IoT communication protocols.

---

## ✨ Key Features

### Hardware & Embedded System (ESP32)
- **Multi-Sensor Integration:** Simultaneously captures data from two different sensors:
    - **KY-039 Heart Rate Sensor:** Detects heartbeats using a transmissive infrared sensor.
    - **HC-SR04 Ultrasonic Sensor:** Measures distance.
- **Real-Time Operating System (RTOS):** Built on FreeRTOS, using a multi-tasking architecture to handle sensor polling and Bluetooth communication concurrently and efficiently.
- **Advanced BPM Algorithm:** Implements a sophisticated beat detection algorithm with signal smoothing and adaptive thresholding to calculate an accurate Beats Per Minute (BPM) value from noisy sensor data.
- **Bluetooth Low Energy (BLE) Server:** The ESP32 acts as a BLE GATT server, advertising its presence and providing a custom service for health data.
- **Command & Control:** Listens for commands from the mobile app (e.g., `SENSORS_ON`, `SENSORS_OFF`) to start and stop data transmission.

### Mobile Application (Flutter)
- **Cross-Platform:** Built with Flutter for a consistent experience on both Android and iOS.
- **BLE Scanner & Client:** Scans for nearby BLE devices and establishes a stable connection with the ESP32 monitor.
- **Live Data Display:**
    - **Real-time Charting:** Displays the user's heart rate on a smooth, scrolling line chart for easy visualization of trends.
    - **Live Data Readouts:** Shows the current BPM and distance values as they are received.
- **Intelligent Heart Rate Zones:**
    - Analyzes the live BPM and categorizes it into zones (e.g., "Resting", "Normal", "High Intensity").
    - The UI color-codes the display to provide instant, at-a-glance feedback on the user's condition.
- **Audible Safety Alarms:**
    - A "smart" alarm system triggers a loud, looping sound if the heart rate remains in a dangerous zone (too low or too high) for a sustained period.
    - The logic is debounced to prevent false alarms during sensor calibration or from momentary signal drops.

---

## 🛠️ Technology Stack

- **Microcontroller:** ESP32
- **Embedded Framework:** ESP-IDF (with FreeRTOS)
- **Programming Language (Embedded):** C
- **Mobile Framework:** Flutter
- **Programming Language (Mobile):** Dart
- **Communication Protocol:** Bluetooth Low Energy (BLE)
- **Flutter Libraries:**
    - `flutter_blue_plus`: For BLE communication.
    - `fl_chart`: For real-time data visualization.
    - `just_audio`: For the audible alarm system.
    - `permission_handler`: For managing Bluetooth and location permissions.

---

## 🚀 How to Use the System

### 1. Hardware Setup
- Connect the KY-039 and HC-SR04 sensors to the ESP32 according to the pin definitions in the C code.
- Ensure the HC-SR04 is powered by a 5V source for stable distance readings.
- Flash the ESP-IDF firmware to the ESP32 board.

### 2. Mobile App
- Build and run the Flutter application on a mobile device.
- Grant the necessary Bluetooth and Location permissions when prompted.
- Tap the "Scan for Devices" button.
- Locate the device named **"ESP32_MONITOR"** in the list and tap "Connect".
- Once connected, turn on the "All Sensors" switch to begin data transmission.
- Navigate to the "Live Monitor" screen to view the real-time data, chart, and heart rate zone.

-
