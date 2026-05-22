class UserProfile {
  final String name;
  final String phone;
  final String bloodGroup;
  final String vehicleType;
  final String medicalNotes;
  final String photoPath;
  final bool isSetUp;

  UserProfile({
    this.name = '',
    this.phone = '',
    this.bloodGroup = 'A+',
    this.vehicleType = 'Two Wheeler',
    this.medicalNotes = '',
    this.photoPath = '',
    this.isSetUp = false,
  });

  UserProfile copyWith({
    String? name,
    String? phone,
    String? bloodGroup,
    String? vehicleType,
    String? medicalNotes,
    String? photoPath,
    bool? isSetUp,
  }) {
    return UserProfile(
      name: name ?? this.name,
      phone: phone ?? this.phone,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      vehicleType: vehicleType ?? this.vehicleType,
      medicalNotes: medicalNotes ?? this.medicalNotes,
      photoPath: photoPath ?? this.photoPath,
      isSetUp: isSetUp ?? this.isSetUp,
    );
  }
}
