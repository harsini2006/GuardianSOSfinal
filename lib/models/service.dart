enum ServiceCategory {
  hospital,
  ambulance,
  police,
  towing,
  medical,
  hotel,
  restaurant,
}

class NearbyService {
  final String id;
  final String name;
  final ServiceCategory category;
  final double distanceKm;
  final int etaMinutes;
  final double rating;
  final String phone;
  final String address;
  final double mockLatOffset; // relative to user location
  final double mockLngOffset; // relative to user location

  NearbyService({
    required this.id,
    required this.name,
    required this.category,
    required this.distanceKm,
    required this.etaMinutes,
    required this.rating,
    required this.phone,
    required this.address,
    required this.mockLatOffset,
    required this.mockLngOffset,
  });

  String get categoryString {
    switch (category) {
      case ServiceCategory.hospital:
        return 'Hospital';
      case ServiceCategory.ambulance:
        return 'Ambulance';
      case ServiceCategory.police:
        return 'Police';
      case ServiceCategory.towing:
        return 'Towing';
      case ServiceCategory.medical:
        return 'Medical Shop';
      case ServiceCategory.hotel:
        return 'Hotel';
      case ServiceCategory.restaurant:
        return 'Restaurant';
    }
  }
}
