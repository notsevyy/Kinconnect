class Contact {
  final String id;
  final String name;
  final String phone;
  final String relationship;
  int escalationOrder;

  Contact({
    required this.id,
    required this.name,
    required this.phone,
    required this.relationship,
    required this.escalationOrder,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'phone': phone,
        'relationship': relationship,
        'escalationOrder': escalationOrder,
      };

  factory Contact.fromMap(Map<String, dynamic> map) => Contact(
        id: map['id'] as String,
        name: map['name'] as String,
        phone: map['phone'] as String,
        relationship: map['relationship'] as String,
        escalationOrder: map['escalationOrder'] as int,
      );
}
