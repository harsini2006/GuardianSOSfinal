enum AlertStatus {
  active,
  resolved,
}

enum AlertType {
  sos,
  accident,
  manual,
}

class EmergencyAlert {
  final String id;
  final String title;
  final String description;
  final DateTime timestamp;
  final AlertStatus status;
  final AlertType type;

  EmergencyAlert({
    required this.id,
    required this.title,
    required this.description,
    required this.timestamp,
    required this.status,
    required this.type,
  });

  String get typeString {
    switch (type) {
      case AlertType.sos:
        return 'SOS Button';
      case AlertType.accident:
        return 'Impact Detected';
      case AlertType.manual:
        return 'Manual Alert';
    }
  }
}
