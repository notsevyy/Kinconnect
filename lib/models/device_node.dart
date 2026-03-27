enum NetworkMode { wifi, lte }

class DeviceNode {
  final String id;
  final String roomName;
  int batteryPercent;
  int signalStrength;
  DateTime lastPing;
  double sensitivity;

  DeviceNode({
    required this.id,
    required this.roomName,
    required this.batteryPercent,
    required this.signalStrength,
    required this.lastPing,
    this.sensitivity = 0.7,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'roomName': roomName,
        'batteryPercent': batteryPercent,
        'signalStrength': signalStrength,
        'lastPing': lastPing.millisecondsSinceEpoch,
        'sensitivity': sensitivity,
      };

  factory DeviceNode.fromMap(Map<String, dynamic> map) => DeviceNode(
        id: map['id'] as String,
        roomName: map['roomName'] as String,
        batteryPercent: map['batteryPercent'] as int,
        signalStrength: map['signalStrength'] as int,
        lastPing:
            DateTime.fromMillisecondsSinceEpoch(map['lastPing'] as int),
        sensitivity: (map['sensitivity'] as num?)?.toDouble() ?? 0.7,
      );
}

class HubStatus {
  final NetworkMode networkMode;
  final int lteSignal;
  final int upsBattery;
  final Duration uptime;

  HubStatus({
    required this.networkMode,
    required this.lteSignal,
    required this.upsBattery,
    required this.uptime,
  });

  Map<String, dynamic> toMap() => {
        'networkMode': networkMode.name,
        'lteSignal': lteSignal,
        'upsBattery': upsBattery,
        'uptime': uptime.inSeconds,
      };

  factory HubStatus.fromMap(Map<String, dynamic> map) => HubStatus(
        networkMode: NetworkMode.values.byName(map['networkMode'] as String),
        lteSignal: map['lteSignal'] as int,
        upsBattery: map['upsBattery'] as int,
        uptime: Duration(seconds: map['uptime'] as int),
      );
}
