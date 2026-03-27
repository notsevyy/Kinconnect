# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

KinConnect — an eldercare/safety monitoring app built with Flutter. It tracks room presence via mmWave sensor nodes, manages medications, provides emergency contact escalation, and monitors device/hub connectivity. Currently uses mock data throughout.

## Common Commands

```bash
flutter pub get          # Install dependencies
flutter run              # Run on connected device/emulator
flutter test             # Run all widget tests
flutter test test/widget_test.dart  # Run a single test file
flutter analyze          # Static analysis (uses flutter_lints)
flutter build windows    # Build for Windows (primary dev platform)
```

All six platforms are configured: Android, iOS, Web, Windows, Linux, macOS.

## Architecture

**State management:** StatefulWidget + setState for local state; MockService exposes broadcast Streams (roomStream, alertStream) for reactive updates.

**Navigation:** Bottom navigation bar with IndexedStack in `main.dart` (MainShell). Five tabs: Home, Activity, Wellness, Safety, Devices.

**Service layer:** `MockService` is a singleton (factory constructor) that owns all mock data and exposes it via Streams and direct accessors. Screens instantiate it directly — there is no DI framework.

**Code layout:**
- `models/` — Data classes with `toMap()`/`fromMap()` serialization and domain enums (RoomState, AlertLevel, NetworkMode)
- `screens/` — One per tab; each is a StatefulWidget subscribing to MockService streams
- `services/` — Only MockService currently
- `widgets/` — Shared components (room_card, node_card, alert_banner, activity_tile)
- `theme/app_theme.dart` — Material 3 theme with semantic colors (critical, warning, safe)

## Key Dependencies

Minimal: only Flutter SDK and cupertino_icons. No external state management, routing, or networking packages. Dart SDK ≥3.11.4.
