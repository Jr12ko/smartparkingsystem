### Complete TechStack Breakdown

---

### 1. Embedded Layer (The Sensors)
**Hardware:** ESP32 (Main) & ESP32-CAM (Secondary).
**Connection:** USB/Serial Cables to Main Computer.

*   **Firmware Language:** C++ (PlatformIO or Arduino IDE).
*   **Libraries:**
    *   `Wire.h`: For I2C communication (ToF Sensor).
    *   `VL53L0X` / `VL53L1X`: Drivers for the Time-of-Flight sensor.
    *   `HardwareSerial`: For reading the mmWave UART stream.
    *   `ArduinoJson`: To package sensor readings (ToF Distance + mmWave Presence) into a single JSON string before sending it over Serial.
*   **ESP32-CAM Firmware:**
    *   **Crucial Change:** Standard ESP32-CAM examples stream over WiFi. Since you are using **cables**, you must write firmware that sends raw JPEG bytes over the Serial port (UART).
    *   **Optimization:** Set the Baud Rate to **2,000,000 (2 Mbps)** or higher. The standard 115200 is too slow for image transfer.

### 2. Edge Processing Layer (The Main Computer)
**Hardware:** Windows PC/Laptop.
**Role:** Ingests data, runs AI, makes decisions, syncs to DB.

*   **Language:** Python 3.10+.
*   **Core Logic Script:** `main_controller.py`
*   **Libraries:**
    *   **Serial Communication:** `pyserial` (To read data from the two USB cables).
    *   **AI/Computer Vision:** `ultralytics` (The official library for **YOLOv8**). It is highly optimized for local inference.
    *   **Image Handling:** `opencv-python` (cv2) or `Pillow` (To construct images from the raw serial bytes coming from ESP32-CAM).
    *   **Backend Sync:** `supabase` (The official Python client).
    *   **Concurrency:** `asyncio` or `threading` (You need to read sensors and run AI simultaneously without blocking).

### 3. Backend Layer (The "Truth" Source)
**Platform:** Supabase.
**Role:** Stores current state and history; broadcasts changes to apps.

*   **Database:** PostgreSQL.
*   **Realtime Engine:** Supabase Realtime (built-in).
*   **Storage:** Supabase Storage buckets (only if you want to upload the "evidence" image when a car parks).
*   **Database Schema (Table: `parking_spots`):**
    *   `id` (int)
    *   `is_occupied` (bool) -> *The final decision.*
    *   `sensor_data` (jsonb) -> *Stores raw ToF/mmWave values.*
    *   `ai_confidence` (float) -> *Stores YOLO confidence score.*
    *   `last_updated` (timestamp)

### 4. Frontend Layer ( The Apps)
**Framework:** Flutter (Single codebase for all).

*   **Platforms:**
    *   **Windows:** Desktop build (Visualizes the parking map).
    *   **Web:** Admin dashboard.
    *   **Android:** Mobile user view.
*   **Key Packages:**
    *   `supabase_flutter`: handles authentication and **real-time database listeners**.
    *   `flutter_riverpod`: For state management (updating the UI when Supabase pushes a change).
    *   `window_manager`: To customize the Windows desktop window size/title bar.

---

### The "Missing" Links & Logic
To make this software stack production-ready, you need to implement the following logic which is currently "lacking" in a standard setup.

#### 1. The "Sensor Fusion" Algorithm (Python Side)
You have three inputs. You need a weighted decision logic in your Python script to avoid false positives.

**Logic Flow:**
1.  **Read ToF:** Distance < 50cm? (State: `TRUE`)
2.  **Read mmWave:** Motion/Presence detected? (State: `TRUE`)
3.  **Run YOLO:** "Car" class detected? (State: `TRUE`, Confidence: 0.85)

**The Python Decision Tree:**
```python
# Pseudo-code for your Python Controller

def determine_status(tof_dist, mmwave_active, yolo_detected):
    score = 0
    
    # Sensors are usually faster and reliable for "presence"
    if tof_dist < 50: score += 40
    if mmwave_active: score += 30
    
    # AI verifies it is actually a car (not a person standing there)
    if yolo_detected: score += 30
    
    # Threshold to mark as occupied
    if score >= 60:
        return True # Occupied
    return False # Free
```

#### 2. State-Change-Only Updates
**Do not** send data to Supabase every second. This will exhaust your write limits and cause UI flickering.
*   **Missing Logic:** Implement a "State Cache" in Python.
    *   *Current Loop:* Calculate `is_occupied`.
    *   *Check:* Is `is_occupied` different from `previous_occupied_state`?
    *   *Action:* If YES, send update to Supabase. If NO, do nothing.

#### 3. Serial Image Reconstruction
This is the hardest part of the software stack.
*   **The Problem:** ESP32-CAM sends data in chunks. Python reads a stream.
*   **The Fix:** You need a "Start Byte" and "End Byte" protocol in your C++ code (e.g., `0xFF, 0xD8` ... `0xFF, 0xD9` for JPEG).
*   **Python Logic:** Your script must buffer incoming serial bytes until it finds the "End Byte", then assemble that buffer into an image for YOLO to process.

#### 4. Keep-Alive / Watchdog
*   **The Risk:** If the USB cable wiggles or the ESP32 crashes, the Python script might freeze waiting for data.
*   **The Fix:** Add `timeout` parameters to your `serial.Serial` calls in Python. If no data is received for 5 seconds, Python should flag an error in the console or reset the connection.

### Summary of Workflow
1.  **ESP32s** push raw data/bytes down USB cables to **PC**.
2.  **PC (Python)** reassembles the image and parses sensor JSON.
3.  **PC (Python)** runs YOLOv8 on the image.
4.  **PC (Python)** calculates the final score (Fusion).
5.  **PC (Python)** updates **Supabase** (only if status changed).
6.  **Supabase** automatically pushes the new status to **Flutter Apps** via WebSocket.
7.  **Flutter Apps** redraw the screen instantly.
