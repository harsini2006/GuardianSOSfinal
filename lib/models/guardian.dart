class Guardian {
  final String id;
  final String name;
  final String phone;
  final String relationship;

  Guardian({
    required this.id,
    required this.name,
    required this.phone,
    required this.relationship,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'phone': phone,
        'relationship': relationship,
      };

  factory Guardian.fromJson(Map<String, dynamic> json) => Guardian(
        id: json['id'] ?? '',
        name: json['name'] ?? '',
        phone: json['phone'] ?? '',
        relationship: json['relationship'] ?? '',
      );
}
