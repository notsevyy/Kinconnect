class ActivityLog {
  final String id;
  final String roomName;
  final String eventType;
  final DateTime timestamp;
  final bool isAnomaly;
  final String? anomalyNote;

  ActivityLog({
    required this.id,
    required this.roomName,
    required this.eventType,
    required this.timestamp,
    this.isAnomaly = false,
    this.anomalyNote,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'roomName': roomName,
        'eventType': eventType,
        'timestamp': timestamp.millisecondsSinceEpoch,
        'isAnomaly': isAnomaly,
        'anomalyNote': anomalyNote,
      };

  factory ActivityLog.fromMap(Map<String, dynamic> map) => ActivityLog(
        id: map['id'] as String,
        roomName: map['roomName'] as String,
        eventType: map['eventType'] as String,
        timestamp:
            DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
        isAnomaly: map['isAnomaly'] as bool? ?? false,
        anomalyNote: map['anomalyNote'] as String?,
      );
}
