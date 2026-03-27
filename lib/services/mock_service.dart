import 'dart:async';
import 'dart:math';

import '../models/room.dart';
import '../models/alert.dart';
import '../models/activity_log.dart';
import '../models/contact.dart';
import '../models/device_node.dart';

class MockService {
  static final MockService _instance = MockService._internal();
  factory MockService() => _instance;
  MockService._internal();

  final _random = Random();

  final _roomController = StreamController<List<Room>>.broadcast();
  final _alertController = StreamController<Alert>.broadcast();

  Stream<List<Room>> get roomStream => _roomController.stream;
  Stream<Alert> get alertStream => _alertController.stream;

  Timer? _roomTimer;
  Timer? _alertTimer;

  final List<Room> _rooms = [
    Room(
      id: 'room_1',
      name: 'Living Room',
      icon: 'weekend',
      state: RoomState.active,
      lastMotion: DateTime.now().subtract(const Duration(minutes: 2)),
    ),
    Room(
      id: 'room_2',
      name: 'Bedroom',
      icon: 'bed',
      state: RoomState.still,
      lastMotion: DateTime.now().subtract(const Duration(minutes: 15)),
    ),
    Room(
      id: 'room_3',
      name: 'Bathroom',
      icon: 'bathtub',
      state: RoomState.empty,
      lastMotion: DateTime.now().subtract(const Duration(hours: 1)),
    ),
    Room(
      id: 'room_4',
      name: 'Kitchen',
      icon: 'kitchen',
      state: RoomState.empty,
      lastMotion: DateTime.now().subtract(const Duration(minutes: 45)),
    ),
  ];

  final List<Alert> _alerts = [];

  late final List<ActivityLog> _activityLogs = _generateTodayLogs();

  final List<Contact> _contacts = [
    Contact(
      id: 'contact_1',
      name: 'Sarah Johnson',
      phone: '+1 (555) 123-4567',
      relationship: 'Daughter',
      escalationOrder: 1,
    ),
    Contact(
      id: 'contact_2',
      name: 'Dr. Michael Chen',
      phone: '+1 (555) 987-6543',
      relationship: 'Primary Physician',
      escalationOrder: 2,
    ),
    Contact(
      id: 'contact_3',
      name: 'James Johnson',
      phone: '+1 (555) 456-7890',
      relationship: 'Son',
      escalationOrder: 3,
    ),
  ];

  final List<DeviceNode> _deviceNodes = [
    DeviceNode(
      id: 'node_1',
      roomName: 'Living Room',
      batteryPercent: 92,
      signalStrength: 85,
      lastPing: DateTime.now().subtract(const Duration(seconds: 30)),
      sensitivity: 0.7,
    ),
    DeviceNode(
      id: 'node_2',
      roomName: 'Bedroom',
      batteryPercent: 78,
      signalStrength: 72,
      lastPing: DateTime.now().subtract(const Duration(seconds: 45)),
      sensitivity: 0.8,
    ),
    DeviceNode(
      id: 'node_3',
      roomName: 'Bathroom',
      batteryPercent: 45,
      signalStrength: 60,
      lastPing: DateTime.now().subtract(const Duration(minutes: 1)),
      sensitivity: 0.9,
    ),
    DeviceNode(
      id: 'node_4',
      roomName: 'Kitchen',
      batteryPercent: 88,
      signalStrength: 90,
      lastPing: DateTime.now().subtract(const Duration(seconds: 15)),
      sensitivity: 0.6,
    ),
  ];

  final HubStatus _hubStatus = HubStatus(
    networkMode: NetworkMode.lte,
    lteSignal: 78,
    upsBattery: 95,
    uptime: const Duration(hours: 72, minutes: 14),
  );

  List<ActivityLog> _generateTodayLogs() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return [
      ActivityLog(
        id: 'log_1',
        roomName: 'Bedroom',
        eventType: 'Motion Detected',
        timestamp: today.add(const Duration(hours: 6, minutes: 30)),
      ),
      ActivityLog(
        id: 'log_2',
        roomName: 'Bathroom',
        eventType: 'Presence Active',
        timestamp: today.add(const Duration(hours: 6, minutes: 35)),
      ),
      ActivityLog(
        id: 'log_3',
        roomName: 'Kitchen',
        eventType: 'Motion Detected',
        timestamp: today.add(const Duration(hours: 7, minutes: 0)),
      ),
      ActivityLog(
        id: 'log_4',
        roomName: 'Kitchen',
        eventType: 'Presence Active',
        timestamp: today.add(const Duration(hours: 7, minutes: 5)),
      ),
      ActivityLog(
        id: 'log_5',
        roomName: 'Living Room',
        eventType: 'Motion Detected',
        timestamp: today.add(const Duration(hours: 8, minutes: 15)),
      ),
      ActivityLog(
        id: 'log_6',
        roomName: 'Living Room',
        eventType: 'Presence Active',
        timestamp: today.add(const Duration(hours: 8, minutes: 16)),
      ),
      ActivityLog(
        id: 'log_7',
        roomName: 'Bathroom',
        eventType: 'Unusual Stillness',
        timestamp: today.add(const Duration(hours: 9, minutes: 45)),
        isAnomaly: true,
        anomalyNote: 'No movement for 25 minutes — no alarm triggered',
      ),
      ActivityLog(
        id: 'log_8',
        roomName: 'Bathroom',
        eventType: 'Motion Resumed',
        timestamp: today.add(const Duration(hours: 10, minutes: 10)),
      ),
      ActivityLog(
        id: 'log_9',
        roomName: 'Kitchen',
        eventType: 'Motion Detected',
        timestamp: today.add(const Duration(hours: 11, minutes: 30)),
      ),
      ActivityLog(
        id: 'log_10',
        roomName: 'Living Room',
        eventType: 'Presence Active',
        timestamp: today.add(const Duration(hours: 12, minutes: 0)),
      ),
      ActivityLog(
        id: 'log_11',
        roomName: 'Bedroom',
        eventType: 'Unusual Stillness',
        timestamp: today.add(const Duration(hours: 13, minutes: 30)),
        isAnomaly: true,
        anomalyNote: 'Extended stillness detected during unusual hours',
      ),
      ActivityLog(
        id: 'log_12',
        roomName: 'Living Room',
        eventType: 'Motion Detected',
        timestamp: today.add(const Duration(hours: 14, minutes: 0)),
      ),
    ];
  }

  List<Room> get rooms => List.unmodifiable(_rooms);
  List<Alert> get alerts => List.unmodifiable(_alerts);
  List<ActivityLog> get activityLogs =>
      List.unmodifiable(_activityLogs.reversed);
  List<Contact> get contacts =>
      List.unmodifiable(_contacts..sort((a, b) => a.escalationOrder.compareTo(b.escalationOrder)));
  List<DeviceNode> get deviceNodes => List.unmodifiable(_deviceNodes);
  HubStatus get hubStatus => _hubStatus;

  bool get hasActiveAlert =>
      _alerts.any((a) => !a.acknowledged && a.level == AlertLevel.critical);

  Map<String, Duration> get dailyRoomSummary {
    final summary = <String, Duration>{};
    final sorted = List<ActivityLog>.from(_activityLogs)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    for (int i = 0; i < sorted.length; i++) {
      final log = sorted[i];
      final nextTime = i + 1 < sorted.length
          ? sorted[i + 1].timestamp
          : DateTime.now();
      final duration = nextTime.difference(log.timestamp);
      summary[log.roomName] =
          (summary[log.roomName] ?? Duration.zero) + duration;
    }
    return summary;
  }

  void startSimulation() {
    _roomTimer?.cancel();
    _alertTimer?.cancel();

    _roomTimer = Timer.periodic(
      Duration(seconds: 5 + _random.nextInt(4)),
      (_) => _simulateRoomChange(),
    );

    _alertTimer = Timer(const Duration(seconds: 10), () {
      final alert = Alert(
        id: 'alert_${DateTime.now().millisecondsSinceEpoch}',
        message: 'Unusual stillness detected in Bathroom — no movement for 20 minutes',
        level: AlertLevel.critical,
        timestamp: DateTime.now(),
      );
      _alerts.add(alert);
      _alertController.add(alert);
    });
  }

  void _simulateRoomChange() {
    final roomIndex = _random.nextInt(_rooms.length);
    final room = _rooms[roomIndex];
    final states = RoomState.values;
    RoomState newState;
    do {
      newState = states[_random.nextInt(states.length)];
    } while (newState == room.state);

    room.state = newState;
    if (newState != RoomState.empty) {
      room.lastMotion = DateTime.now();
    }

    _activityLogs.add(ActivityLog(
      id: 'log_${DateTime.now().millisecondsSinceEpoch}',
      roomName: room.name,
      eventType: newState == RoomState.active
          ? 'Motion Detected'
          : newState == RoomState.still
              ? 'Stillness Detected'
              : 'Room Vacated',
      timestamp: DateTime.now(),
    ));

    _roomController.add(List.from(_rooms));
  }

  void acknowledgeAlert(String alertId) {
    final alert = _alerts.firstWhere((a) => a.id == alertId);
    alert.acknowledged = true;
  }

  void updateNodeSensitivity(String nodeId, double sensitivity) {
    final node = _deviceNodes.firstWhere((n) => n.id == nodeId);
    node.sensitivity = sensitivity;
  }

  void reorderContacts(List<Contact> reordered) {
    _contacts.clear();
    for (int i = 0; i < reordered.length; i++) {
      reordered[i].escalationOrder = i + 1;
      _contacts.add(reordered[i]);
    }
  }

  void triggerPanicAlert() {
    final alert = Alert(
      id: 'panic_${DateTime.now().millisecondsSinceEpoch}',
      message: 'PANIC BUTTON PRESSED — Emergency alert sent to all contacts',
      level: AlertLevel.critical,
      timestamp: DateTime.now(),
    );
    _alerts.add(alert);
    _alertController.add(alert);
  }

  void dispose() {
    _roomTimer?.cancel();
    _alertTimer?.cancel();
    _roomController.close();
    _alertController.close();
  }
}
