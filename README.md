# KinConnect

An eldercare safety monitoring app built with Flutter. KinConnect tracks room presence via mmWave sensor nodes, provides emergency contact escalation, and monitors device/hub connectivity — giving caregivers peace of mind.

> Currently running on mock data for development and demonstration purposes.

## Features

- **Room Monitoring** — Real-time room presence tracking (Living Room, Bedroom, Bathroom, Kitchen) with active/still/empty states
- **Activity Timeline** — Filterable log of motion events, presence changes, and anomaly detections with daily summaries
- **Safety Alerts** — Instant alert banners for safety events with acknowledge flow
- **Emergency Contacts** — Drag-to-reorder escalation list with one-tap calling and a long-press panic button
- **Device Management** — Hub status monitoring (LTE/WiFi, UPS battery, uptime) and per-room sensor node cards with sensitivity sliders and battery warnings
- **Settings** — Edit profile, notification preferences, and sign out
- **Auth Flow** — Splash screen with session-based routing, onboarding carousel for first launch, sign up and login screens

## Screenshots

*Coming soon*

## Getting Started

### Prerequisites

- Flutter SDK >= 3.11.4
- Dart SDK >= 3.11.4

### Install & Run

```bash
flutter pub get
flutter run
```

### Build

```bash
flutter build windows    # Windows
flutter build apk        # Android
flutter build ios         # iOS
flutter build web         # Web
```

## Project Structure

```
lib/
  main.dart              # App entry point, MainShell with bottom nav
  models/                # Data classes (Room, Alert, Contact, DeviceNode, ActivityLog)
  screens/               # One screen per feature tab + auth screens
  services/
    auth_service.dart    # File-based JSON session persistence
    mock_service.dart    # Singleton with broadcast Streams for reactive data
  theme/
    app_colors.dart      # Semantic color system with room color mapping
    app_theme.dart       # Material 3 theme configuration
  widgets/               # Shared components (room_card, node_card, alert_banner, activity_tile)
assets/
  images/                # App logos
```

## Architecture

- **State management:** StatefulWidget + setState with StreamSubscription for reactive updates
- **Navigation:** Bottom nav bar with IndexedStack for tab state persistence
- **Data layer:** MockService singleton exposes broadcast Streams (`roomStream`, `alertStream`) and direct accessors
- **Persistence:** File-based JSON storage via `dart:io` (no external dependencies)
- **Dependencies:** Minimal — Flutter SDK and cupertino_icons only

## Platforms

Android, iOS, Web, Windows, Linux, macOS

## License

Private — not published to pub.dev.
