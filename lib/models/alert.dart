enum AlertLevel { info, warning, critical }

class Alert {
  final String id;
  final String message;
  final AlertLevel level;
  final DateTime timestamp;
  bool acknowledged;

  Alert({
    required this.id,
    required this.message,
    required this.level,
    required this.timestamp,
    this.acknowledged = false,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'message': message,
        'level': level.name,
        'timestamp': timestamp.millisecondsSinceEpoch,
        'acknowledged': acknowledged,
      };

  factory Alert.fromMap(Map<String, dynamic> map) => Alert(
        id: map['id'] as String,
        message: map['message'] as String,
        level: AlertLevel.values.byName(map['level'] as String),
        timestamp:
            DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
        acknowledged: map['acknowledged'] as bool? ?? false,
      );
}
