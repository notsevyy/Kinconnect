enum RoomState { active, still, empty }

class Room {
  final String id;
  final String name;
  final String icon;
  RoomState state;
  DateTime lastMotion;

  Room({
    required this.id,
    required this.name,
    required this.icon,
    required this.state,
    required this.lastMotion,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'icon': icon,
        'state': state.name,
        'lastMotion': lastMotion.millisecondsSinceEpoch,
      };

  factory Room.fromMap(Map<String, dynamic> map) => Room(
        id: map['id'] as String,
        name: map['name'] as String,
        icon: map['icon'] as String,
        state: RoomState.values.byName(map['state'] as String),
        lastMotion:
            DateTime.fromMillisecondsSinceEpoch(map['lastMotion'] as int),
      );

  String get stateLabel {
    switch (state) {
      case RoomState.active:
        return 'Active';
      case RoomState.still:
        return 'Still';
      case RoomState.empty:
        return 'Empty';
    }
  }
}
