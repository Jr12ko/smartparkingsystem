# 🚗 Smart Parking System

<div align="center">

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![AWS](https://img.shields.io/badge/AWS-232F3E?style=for-the-badge&logo=amazon-aws&logoColor=white)

A modern, cross-platform Flutter application for real-time parking management and navigation.

[Features](#-features) • [Screenshots](#-screenshots) • [Installation](#-installation) • [Architecture](#-architecture) • [Contributing](#-contributing)

</div>

---

## ✨ Features

### 🔐 Authentication

- **Secure Login & Registration** — Powered by AWS Amplify Cognito
- **Email Verification** — OTP-based account confirmation
- **Password Recovery** — Self-service password reset flow

### 🗺️ Smart Parking Map

- **Real-time Visualization** — Live parking spot availability display
- **Interactive Navigation** — Turn-by-turn guidance to selected spots
- **Spot Status Indicators** — Clear visual distinction between available/occupied

### 👨‍💼 Admin Panel

- **Grid Designer** — Visual drag-and-drop parking lot layout editor
- **Multi-select Tools** — Bulk editing with drag selection
- **Measurement Tools** — Ruler tool for precise measurements
- **Rotation Controls** — Rotate parking spots with hotkeys
- **Import/Export** — Save and load parking grid configurations as JSON
- **Undo/Redo Stack** — Full history support for design changes

### 🎨 User Experience

- **Dark/Light Theme** — Toggle between themes with persistent preferences
- **Smooth Animations** — Polished micro-interactions and transitions
- **Responsive Design** — Works on mobile, tablet, desktop, and web

### 📊 Analytics

- **Statistics Dashboard** — View parking usage metrics and trends

---

## 🛠️ Tech Stack

| Category             | Technology              |
| -------------------- | ----------------------- |
| **Framework**        | Flutter 3.6+            |
| **Language**         | Dart                    |
| **Authentication**   | AWS Amplify (Cognito)   |
| **State Management** | Provider                |
| **Local Storage**    | SharedPreferences       |
| **Routing**          | GoRouter                |
| **File Handling**    | FilePicker, package:web |

### Supported Platforms

| Platform   | Status       |
| ---------- | ------------ |
| 🌐 Web     | ✅ Supported |
| 🤖 Android | ✅ Supported |
| 🍎 iOS     | ✅ Supported |
| 🪟 Windows | ✅ Supported |
| 🍏 macOS   | ✅ Supported |
| 🐧 Linux   | ✅ Supported |

---

## 📦 Installation

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (v3.6.1+)
- [Dart SDK](https://dart.dev/get-dart)
- An AWS Account (for Amplify/Cognito)

### Quick Start

```bash
# 1. Clone the repository
git clone https://github.com/yourusername/smartparkingsystem.git
cd smartparkingsystem

# 2. Install dependencies
flutter pub get

# 3. Run the application
flutter run
```

### AWS Amplify Configuration

The app uses AWS Cognito for authentication. To configure:

1. **Using existing config**: Update the configuration in `lib/services/amplifyconfiguration.dart`

2. **Creating new Cognito pool**:
   ```bash
   amplify init
   amplify add auth
   amplify push
   ```

---

## 📂 Project Structure

```
lib/
├── main.dart                    # App entry point & Amplify setup
│
├── models/                      # Data models
│   ├── parking_grid.dart        # Parking grid configuration
│   └── parking_spot.dart        # Individual parking spot model
│
├── screens/                     # UI Screens
│   ├── admin/                   # Admin-only screens
│   │   ├── grid_designer_screen.dart   # Visual grid editor
│   │   ├── grid_designer_web.dart      # Web file operations
│   │   └── grid_designer_io.dart       # Desktop file operations
│   │
│   ├── login_screen.dart        # User login
│   ├── register_screen.dart     # User registration
│   ├── confirm_signup_screen.dart # Email verification
│   ├── resetpassword_screen.dart # Password recovery
│   ├── home_screen.dart         # Main dashboard
│   ├── map.dart                 # Parking map & navigation
│   ├── setting_screen.dart      # User settings
│   ├── statistics_screen.dart   # Analytics dashboard
│   └── admin_screen.dart        # Admin panel entry
│
├── services/                    # Business logic & APIs
│   ├── auth_service.dart        # Authentication service
│   ├── amplifyconfiguration.dart # AWS config
│   ├── theme_provider.dart      # Theme state management
│   └── admin_router.dart        # Admin navigation
│
└── widgets/                     # Reusable components
    ├── fade_slide_transition.dart # Animation widget
    ├── navigation.dart          # Navigation bar
    └── scale_button.dart        # Animated button
```

---

## 🏗️ Architecture

This application is the **frontend layer** of a complete IoT Smart Parking ecosystem:

```
┌─────────────────────────────────────────────────────────────────┐
│                      SMART PARKING SYSTEM                       │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────────────┐ │
│  │   SENSORS   │───▶│    EDGE     │───▶│      BACKEND        │ │
│  │  ESP32/ToF  │    │   Python    │    │  AWS/Supabase DB    │ │
│  │  mmWave     │    │   YOLOv8    │    │                     │ │
│  └─────────────┘    └─────────────┘    └──────────┬──────────┘ │
│                                                    │            │
│                                                    ▼            │
│                                        ┌─────────────────────┐  │
│                                        │   FRONTEND (This)   │  │
│                                        │   Flutter App       │  │
│                                        │   Real-time Updates │  │
│                                        └─────────────────────┘  │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### Components

| Layer        | Description                                                     |
| ------------ | --------------------------------------------------------------- |
| **Sensors**  | ESP32 with ToF/mmWave sensors and cameras for vehicle detection |
| **Edge**     | Local Python server running YOLOv8 for real-time processing     |
| **Backend**  | Cloud database storing parking state and user data              |
| **Frontend** | This Flutter app — subscribes to updates for live availability  |

---

## 🎨 Theming

The app supports both **Dark** and **Light** themes with smooth transitions:

- Theme preference persists across sessions via `SharedPreferences`
- Toggle available in Settings screen
- All components respect the current theme

---

## 🔧 Admin Features

Access the admin panel from Settings (requires admin privileges):

### Grid Designer Tools

| Tool       | Description                    | Shortcut |
| ---------- | ------------------------------ | -------- |
| **Select** | Click to select parking spots  | -        |
| **Pan**    | Drag to pan the canvas         | -        |
| **Add**    | Click to add new parking spots | -        |
| **Delete** | Remove selected spots          | `Delete` |
| **Rotate** | Rotate selected spots 90°      | `R`      |
| **Ruler**  | Measure distances on canvas    | -        |

### Multi-Select

- Hold and drag to select multiple spots
- Edit properties of all selected spots at once
- Bulk delete with single action

---

## 🤝 Contributing

Contributions are welcome! Here's how to get started:

1. **Fork** the repository
2. **Create** a feature branch: `git checkout -b feature/amazing-feature`
3. **Commit** your changes: `git commit -m 'Add amazing feature'`
4. **Push** to the branch: `git push origin feature/amazing-feature`
5. **Open** a Pull Request

### Development Guidelines

- Follow [Dart style guide](https://dart.dev/guides/language/effective-dart/style)
- Write meaningful commit messages
- Add comments for complex logic
- Test on multiple platforms before submitting

---

## 📄 License

This project is licensed under the **MIT License** — see the [LICENSE](LICENSE) file for details.

---

<div align="center">

Made with ❤️ using Flutter

</div>
