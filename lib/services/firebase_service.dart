import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

import '../models/room.dart';
import '../models/alert.dart';
import '../models/activity_log.dart';
import '../models/contact.dart';
import '../models/device_node.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  final _firestore = FirebaseFirestore.instance;
  final _rtdb = FirebaseDatabase.instance;

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  // --------------- Stream controllers ---------------
  final _roomController = StreamController<List<Room>>.broadcast();
  final _alertController = StreamController<Alert>.broadcast();
  final _activityController = StreamController<List<ActivityLog>>.broadcast();
  final _contactController = StreamController<List<Contact>>.broadcast();
  final _nodeController = StreamController<List<DeviceNode>>.broadcast();
  final _hubController = StreamController<HubStatus>.broadcast();

  Stream<List<Room>> get roomStream => _roomController.stream;
  Stream<Alert> get alertStream => _alertController.stream;
  Stream<List<ActivityLog>> get activityStream => _activityController.stream;
  Stream<List<Contact>> get contactStream => _contactController.stream;
  Stream<List<DeviceNode>> get nodeStream => _nodeController.stream;
  Stream<HubStatus> get hubStream => _hubController.stream;

  // Cached data
  List<Room> _rooms = [];
  List<Alert> _alerts = [];
  List<ActivityLog> _activityLogs = [];
  List<Contact> _contacts = [];
  List<DeviceNode> _deviceNodes = [];
  HubStatus _hubStatus = HubStatus(
    networkMode: NetworkMode.lte,
    lteSignal: 0,
    upsBattery: 0,
    uptime: Duration.zero,
  );

  // Firestore subscriptions
  StreamSubscription? _roomSub;
  StreamSubscription? _alertSub;
  StreamSubscription? _activitySub;
  StreamSubscription? _contactSub;
  StreamSubscription? _hubSub;
  StreamSubscription? _nodesSub;

  // --------------- Public accessors ---------------
  List<Room> get rooms => List.unmodifiable(_rooms);
  List<Alert> get alerts => List.unmodifiable(_alerts);
  List<ActivityLog> get activityLogs => List.unmodifiable(_activityLogs);
  List<Contact> get contacts => List.unmodifiable(
      _contacts..sort((a, b) => a.escalationOrder.compareTo(b.escalationOrder)));
  List<DeviceNode> get deviceNodes => List.unmodifiable(_deviceNodes);
  HubStatus get hubStatus => _hubStatus;

  bool get hasActiveAlert =>
      _alerts.any((a) => !a.acknowledged && a.level == AlertLevel.critical);

  Map<String, Duration> get dailyRoomSummary {
    final todayStart = DateTime(
        DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final todayLogs = _activityLogs
        .where((l) => l.timestamp.isAfter(todayStart))
        .toList();
    final summary = <String, Duration>{};
    final sorted = List<ActivityLog>.from(todayLogs)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    for (int i = 0; i < sorted.length; i++) {
      final log = sorted[i];
      final nextTime =
          i + 1 < sorted.length ? sorted[i + 1].timestamp : DateTime.now();
      final duration = nextTime.difference(log.timestamp);
      summary[log.roomName] =
          (summary[log.roomName] ?? Duration.zero) + duration;
    }
    return summary;
  }

  // --------------- Start listening ---------------
  void startSimulation() {
    final uid = _uid;
    if (uid == null) return;

    _listenRooms(uid);
    _listenAlerts(uid);
    _listenActivity(uid);
    _listenContacts(uid);
    _listenHub(uid);
    _listenNodes(uid);
  }

  void _listenRooms(String uid) {
    _roomSub?.cancel();
    _roomSub = _firestore
        .collection('rooms')
        .doc(uid)
        .collection('items')
        .snapshots()
        .listen((snap) {
      _rooms = snap.docs.map((doc) {
        final data = doc.data();
        return Room(
          id: doc.id,
          name: data['name'] as String? ?? '',
          icon: data['icon'] as String? ?? 'home',
          state: _parseRoomState(data['state'] as String? ?? 'empty'),
          lastMotion: (data['lastMovement'] as Timestamp?)?.toDate() ??
              DateTime.now(),
        );
      }).toList();
      _roomController.add(_rooms);
    }, onError: (_) {});
  }

  void _listenAlerts(String uid) {
    _alertSub?.cancel();
    _alertSub = _firestore
        .collection('alerts')
        .doc(uid)
        .collection('items')
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .listen((snap) {
      _alerts = snap.docs.map((doc) {
        final data = doc.data();
        return Alert(
          id: doc.id,
          message: data['message'] as String? ?? '',
          level: _parseAlertLevel(data['level'] as String? ?? 'info'),
          timestamp: (data['timestamp'] as Timestamp?)?.toDate() ??
              DateTime.now(),
          acknowledged: data['acknowledged'] as bool? ?? false,
        );
      }).toList();
      final unacked = _alerts.where((a) => !a.acknowledged);
      if (unacked.isNotEmpty) {
        _alertController.add(unacked.last);
      }
    }, onError: (_) {});
  }

  void _listenActivity(String uid) {
    _activitySub?.cancel();
    _activitySub = _firestore
        .collection('alerts')
        .doc(uid)
        .collection('items')
        .orderBy('timestamp', descending: true)
        .limit(100)
        .snapshots()
        .listen((snap) {
      _activityLogs = snap.docs.map((doc) {
        final data = doc.data();
        final level = data['level'] as String? ?? 'info';
        return ActivityLog(
          id: doc.id,
          roomName: data['room'] as String? ?? 'Unknown',
          eventType: data['message'] as String? ?? level,
          timestamp: (data['timestamp'] as Timestamp?)?.toDate() ??
              DateTime.now(),
          isAnomaly: level == 'warning',
          anomalyNote: level == 'warning' ? (data['message'] as String?) : null,
        );
      }).toList();
      _activityController.add(_activityLogs);
    }, onError: (_) {});
  }

  void _listenContacts(String uid) {
    _contactSub?.cancel();
    _contactSub = _firestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .listen((snap) {
      final data = snap.data();
      if (data == null) return;
      final contactsList = data['contacts'] as List<dynamic>? ?? [];
      _contacts = contactsList.asMap().entries.map((entry) {
        final c = entry.value as Map<String, dynamic>;
        return Contact(
          id: c['id'] as String? ?? 'contact_${entry.key}',
          name: c['name'] as String? ?? '',
          phone: c['phone'] as String? ?? '',
          relationship: c['relationship'] as String? ?? '',
          escalationOrder: c['escalationOrder'] as int? ?? entry.key + 1,
        );
      }).toList();
      _contactController.add(_contacts);
    }, onError: (_) {});
  }

  void _listenHub(String uid) {
    _hubSub?.cancel();
    _hubSub = _rtdb.ref('hubs/$uid').onValue.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return;
      _hubStatus = HubStatus(
        networkMode: (data['networkMode'] as String?) == 'wifi'
            ? NetworkMode.wifi
            : NetworkMode.lte,
        lteSignal: (data['lteSignal'] as num?)?.toInt() ?? 0,
        upsBattery: (data['battery'] as num?)?.toInt() ?? 0,
        uptime: Duration(seconds: (data['uptime'] as num?)?.toInt() ?? 0),
      );
      _hubController.add(_hubStatus);
    }, onError: (_) {});
  }

  void _listenNodes(String uid) {
    _nodesSub?.cancel();
    _nodesSub = _rtdb.ref('nodes/$uid').onValue.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return;
      _deviceNodes = data.entries.map((entry) {
        final nodeId = entry.key as String;
        final n = Map<String, dynamic>.from(entry.value as Map);
        return DeviceNode(
          id: nodeId,
          roomName: n['room'] as String? ?? '',
          batteryPercent: (n['battery'] as num?)?.toInt() ?? 0,
          signalStrength: (n['signal'] as num?)?.toInt() ?? 0,
          lastPing: n['lastPing'] != null
              ? DateTime.fromMillisecondsSinceEpoch(
                  (n['lastPing'] as num).toInt())
              : DateTime.now(),
          sensitivity: ((n['sensitivity'] as num?)?.toDouble() ?? 70.0) / 100.0,
        );
      }).toList();
      _nodeController.add(_deviceNodes);
    }, onError: (_) {});
  }

  // --------------- Per-screen seeding ---------------

  Future<void> seedRoomsIfEmpty() async {
    final uid = _uid;
    if (uid == null) return;
    final snap = await _firestore
        .collection('rooms')
        .doc(uid)
        .collection('items')
        .limit(1)
        .get();
    if (snap.docs.isNotEmpty) return;

    final batch = _firestore.batch();
    final col = _firestore.collection('rooms').doc(uid).collection('items');
    final defaultRooms = [
      {'name': 'Living Room', 'icon': 'weekend', 'state': 'active'},
      {'name': 'Bedroom', 'icon': 'bed', 'state': 'still'},
      {'name': 'Bathroom', 'icon': 'bathtub', 'state': 'empty'},
      {'name': 'Kitchen', 'icon': 'kitchen', 'state': 'empty'},
    ];
    for (int i = 0; i < defaultRooms.length; i++) {
      batch.set(col.doc('room_${i + 1}'), {
        ...defaultRooms[i],
        'lastMovement': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }

  Future<void> seedAlertsIfEmpty() async {
    final uid = _uid;
    if (uid == null) return;
    final snap = await _firestore
        .collection('alerts')
        .doc(uid)
        .collection('items')
        .limit(1)
        .get();
    if (snap.docs.isNotEmpty) return;

    final now = DateTime.now();
    final batch = _firestore.batch();
    final col = _firestore.collection('alerts').doc(uid).collection('items');
    final sampleAlerts = [
      {
        'message': 'Motion detected',
        'level': 'info',
        'room': 'Living Room',
        'timestamp': Timestamp.fromDate(now.subtract(const Duration(minutes: 5))),
        'acknowledged': false,
      },
      {
        'message': 'Extended stillness — no movement for 45 minutes',
        'level': 'warning',
        'room': 'Bedroom',
        'timestamp': Timestamp.fromDate(now.subtract(const Duration(minutes: 30))),
        'acknowledged': false,
      },
      {
        'message': 'Presence active',
        'level': 'info',
        'room': 'Kitchen',
        'timestamp': Timestamp.fromDate(now.subtract(const Duration(hours: 1))),
        'acknowledged': false,
      },
      {
        'message': 'Room vacated',
        'level': 'info',
        'room': 'Bathroom',
        'timestamp': Timestamp.fromDate(now.subtract(const Duration(hours: 1, minutes: 20))),
        'acknowledged': false,
      },
      {
        'message': 'Motion detected',
        'level': 'info',
        'room': 'Bathroom',
        'timestamp': Timestamp.fromDate(now.subtract(const Duration(hours: 1, minutes: 45))),
        'acknowledged': false,
      },
      {
        'message': 'Unusual activity pattern — movement at unusual hour',
        'level': 'warning',
        'room': 'Kitchen',
        'timestamp': Timestamp.fromDate(now.subtract(const Duration(hours: 2))),
        'acknowledged': false,
      },
      {
        'message': 'Presence active',
        'level': 'info',
        'room': 'Living Room',
        'timestamp': Timestamp.fromDate(now.subtract(const Duration(hours: 2, minutes: 30))),
        'acknowledged': false,
      },
      {
        'message': 'Motion detected',
        'level': 'info',
        'room': 'Bedroom',
        'timestamp': Timestamp.fromDate(now.subtract(const Duration(hours: 3))),
        'acknowledged': false,
      },
    ];
    for (int i = 0; i < sampleAlerts.length; i++) {
      batch.set(col.doc('alert_seed_${i + 1}'), sampleAlerts[i]);
    }
    await batch.commit();
  }

  Future<void> seedContactsIfEmpty() async {
    final uid = _uid;
    if (uid == null) return;
    final doc = await _firestore.collection('users').doc(uid).get();
    final data = doc.data();
    final contactsList = data?['contacts'] as List<dynamic>? ?? [];
    if (contactsList.isNotEmpty) return;

    await _firestore.collection('users').doc(uid).set({
      'contacts': [
        {
          'id': 'contact_1',
          'name': 'Sarah Johnson',
          'phone': '+1 (555) 123-4567',
          'relationship': 'Daughter',
          'escalationOrder': 1,
        },
        {
          'id': 'contact_2',
          'name': 'Dr. Michael Chen',
          'phone': '+1 (555) 987-6543',
          'relationship': 'Primary Physician',
          'escalationOrder': 2,
        },
        {
          'id': 'contact_3',
          'name': 'James Johnson',
          'phone': '+1 (555) 456-7890',
          'relationship': 'Son',
          'escalationOrder': 3,
        },
      ],
      'escalationOrder': ['contact_1', 'contact_2', 'contact_3'],
    }, SetOptions(merge: true));
  }

  Future<void> seedHubNodesIfEmpty() async {
    final uid = _uid;
    if (uid == null) return;

    final hubSnap = await _rtdb.ref('hubs/$uid').get();
    if (!hubSnap.exists) {
      await _rtdb.ref('hubs/$uid').set({
        'battery': 95,
        'networkMode': 'lte',
        'lteSignal': 78,
        'uptime': 259200,
        'lastSeen': ServerValue.timestamp,
      });
    }

    final nodesSnap = await _rtdb.ref('nodes/$uid').get();
    if (!nodesSnap.exists) {
      await _rtdb.ref('nodes/$uid').set({
        'node_1': {
          'room': 'Living Room',
          'battery': 92,
          'signal': 85,
          'lastPing': ServerValue.timestamp,
          'online': true,
          'sensitivity': 70,
        },
        'node_2': {
          'room': 'Bedroom',
          'battery': 78,
          'signal': 72,
          'lastPing': ServerValue.timestamp,
          'online': true,
          'sensitivity': 80,
        },
        'node_3': {
          'room': 'Bathroom',
          'battery': 45,
          'signal': 60,
          'lastPing': ServerValue.timestamp,
          'online': true,
          'sensitivity': 90,
        },
        'node_4': {
          'room': 'Kitchen',
          'battery': 88,
          'signal': 90,
          'lastPing': ServerValue.timestamp,
          'online': true,
          'sensitivity': 60,
        },
      });
    }
  }

  // --------------- Actions ---------------

  Future<void> acknowledgeAlert(String alertId) async {
    final uid = _uid;
    if (uid == null) return;
    try {
      await _firestore
          .collection('alerts')
          .doc(uid)
          .collection('items')
          .doc(alertId)
          .update({'acknowledged': true});
    } catch (_) {
      final alert = _alerts.where((a) => a.id == alertId).firstOrNull;
      if (alert != null) alert.acknowledged = true;
    }
  }

  Future<void> updateNodeSensitivity(String nodeId, double sensitivity) async {
    final uid = _uid;
    if (uid == null) return;
    try {
      await _rtdb
          .ref('nodes/$uid/$nodeId/sensitivity')
          .set((sensitivity * 100).round());
    } catch (_) {
      final node = _deviceNodes.where((n) => n.id == nodeId).firstOrNull;
      if (node != null) node.sensitivity = sensitivity;
    }
  }

  Future<void> reorderContacts(List<Contact> reordered) async {
    final uid = _uid;
    if (uid == null) return;
    for (int i = 0; i < reordered.length; i++) {
      reordered[i].escalationOrder = i + 1;
    }
    _contacts = List.from(reordered);
    try {
      await _firestore.collection('users').doc(uid).update({
        'contacts': reordered.map((c) => c.toMap()).toList(),
        'escalationOrder': reordered.map((c) => c.id).toList(),
      });
    } catch (_) {}
  }

  Future<void> triggerPanicAlert() async {
    final uid = _uid;
    if (uid == null) return;
    try {
      await _firestore
          .collection('alerts')
          .doc(uid)
          .collection('items')
          .add({
        'message':
            'PANIC BUTTON PRESSED — Emergency alert sent to all contacts',
        'level': 'critical',
        'room': 'All',
        'timestamp': FieldValue.serverTimestamp(),
        'acknowledged': false,
      });
    } catch (_) {
      final alert = Alert(
        id: 'panic_${DateTime.now().millisecondsSinceEpoch}',
        message:
            'PANIC BUTTON PRESSED — Emergency alert sent to all contacts',
        level: AlertLevel.critical,
        timestamp: DateTime.now(),
      );
      _alerts.add(alert);
      _alertController.add(alert);
    }
  }

  // --------------- Seed data on signup ---------------
  Future<void> seedInitialData(String uid, String name, String seniorName) async {
    final batch = _firestore.batch();

    final userRef = _firestore.collection('users').doc(uid);
    batch.set(userRef, {
      'name': name,
      'seniorName': seniorName,
      'contacts': [
        {
          'id': 'contact_1',
          'name': 'Sarah Johnson',
          'phone': '+1 (555) 123-4567',
          'relationship': 'Daughter',
          'escalationOrder': 1,
        },
        {
          'id': 'contact_2',
          'name': 'Dr. Michael Chen',
          'phone': '+1 (555) 987-6543',
          'relationship': 'Primary Physician',
          'escalationOrder': 2,
        },
        {
          'id': 'contact_3',
          'name': 'James Johnson',
          'phone': '+1 (555) 456-7890',
          'relationship': 'Son',
          'escalationOrder': 3,
        },
      ],
      'escalationOrder': ['contact_1', 'contact_2', 'contact_3'],
    });

    final roomsCol =
        _firestore.collection('rooms').doc(uid).collection('items');
    final defaultRooms = [
      {'name': 'Living Room', 'icon': 'weekend', 'state': 'active'},
      {'name': 'Bedroom', 'icon': 'bed', 'state': 'still'},
      {'name': 'Bathroom', 'icon': 'bathtub', 'state': 'empty'},
      {'name': 'Kitchen', 'icon': 'kitchen', 'state': 'empty'},
    ];
    for (int i = 0; i < defaultRooms.length; i++) {
      batch.set(roomsCol.doc('room_${i + 1}'), {
        ...defaultRooms[i],
        'lastMovement': FieldValue.serverTimestamp(),
      });
    }

    final medsCol =
        _firestore.collection('medications').doc(uid).collection('items');
    final defaultMeds = [
      {'name': 'Blood Pressure Med', 'time': '08:00', 'taken': false},
      {'name': 'Vitamin D', 'time': '12:00', 'taken': false},
      {'name': 'Evening Medication', 'time': '20:00', 'taken': false},
    ];
    for (int i = 0; i < defaultMeds.length; i++) {
      batch.set(medsCol.doc('med_${i + 1}'), {
        ...defaultMeds[i],
        'takenAt': null,
      });
    }

    await batch.commit();

    final hubRef = _rtdb.ref('hubs/$uid');
    await hubRef.set({
      'battery': 95,
      'networkMode': 'lte',
      'lteSignal': 78,
      'uptime': 259200,
      'lastSeen': ServerValue.timestamp,
    });

    final nodesRef = _rtdb.ref('nodes/$uid');
    await nodesRef.set({
      'node_1': {
        'room': 'Living Room',
        'battery': 92,
        'signal': 85,
        'lastPing': ServerValue.timestamp,
        'online': true,
        'sensitivity': 70,
      },
      'node_2': {
        'room': 'Bedroom',
        'battery': 78,
        'signal': 72,
        'lastPing': ServerValue.timestamp,
        'online': true,
        'sensitivity': 80,
      },
      'node_3': {
        'room': 'Bathroom',
        'battery': 45,
        'signal': 60,
        'lastPing': ServerValue.timestamp,
        'online': true,
        'sensitivity': 90,
      },
      'node_4': {
        'room': 'Kitchen',
        'battery': 88,
        'signal': 90,
        'lastPing': ServerValue.timestamp,
        'online': true,
        'sensitivity': 60,
      },
    });
  }

  // --------------- Cleanup ---------------
  void dispose() {
    _roomSub?.cancel();
    _alertSub?.cancel();
    _activitySub?.cancel();
    _contactSub?.cancel();
    _hubSub?.cancel();
    _nodesSub?.cancel();
  }

  // --------------- Helpers ---------------
  static RoomState _parseRoomState(String s) {
    switch (s) {
      case 'active':
        return RoomState.active;
      case 'still':
        return RoomState.still;
      default:
        return RoomState.empty;
    }
  }

  static AlertLevel _parseAlertLevel(String s) {
    switch (s) {
      case 'critical':
        return AlertLevel.critical;
      case 'warning':
        return AlertLevel.warning;
      default:
        return AlertLevel.info;
    }
  }
}
