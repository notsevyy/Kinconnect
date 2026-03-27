class Medication {
  final String id;
  final String name;
  final String dosage;
  final DateTime nextDue;
  bool taken;

  Medication({
    required this.id,
    required this.name,
    required this.dosage,
    required this.nextDue,
    this.taken = false,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'dosage': dosage,
        'nextDue': nextDue.millisecondsSinceEpoch,
        'taken': taken,
      };

  factory Medication.fromMap(Map<String, dynamic> map) => Medication(
        id: map['id'] as String,
        name: map['name'] as String,
        dosage: map['dosage'] as String,
        nextDue:
            DateTime.fromMillisecondsSinceEpoch(map['nextDue'] as int),
        taken: map['taken'] as bool? ?? false,
      );
}
