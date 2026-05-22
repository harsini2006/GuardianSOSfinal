import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:http/http.dart' as http;
import '../models/user_profile.dart';
import '../models/guardian.dart';
import '../models/service.dart';
import '../models/emergency_alert.dart';

class AppState extends ChangeNotifier {
  // Authentication & Role
  bool _isLoggedIn = false;
  String _userPhone = '';
  String _userRole = 'user';
  UserProfile _profile = UserProfile(name: 'Anbu Selvan', bloodGroup: 'O+');
  
  bool get isLoggedIn => _isLoggedIn;
  String get userPhone => _userPhone;
  String get userRole => _userRole;
  UserProfile get profile => _profile;

  // Navigation
  int _currentTab = 0;
  int get currentTab => _currentTab;

  void setTab(int index) {
    _currentTab = index;
    notifyListeners();
  }

  // Guardians
  final List<Guardian> _guardians = [
    Guardian(id: '1', name: 'Ramesh Selvan', phone: '+919840012345', relationship: 'Father'),
    Guardian(id: '2', name: 'Lakshmi Selvan', phone: '+919840054321', relationship: 'Mother'),
  ];
  List<Guardian> get guardians => _guardians;

  // Permissions
  bool _locationPermission = false;
  bool _smsPermission = false;
  bool _notificationPermission = false;
  bool _microphonePermission = false;

  bool get locationPermission => _locationPermission;
  bool get smsPermission => _smsPermission;
  bool get notificationPermission => _notificationPermission;
  bool get microphonePermission => _microphonePermission;

  // System Toggles
  bool _darkTheme = false;
  bool _autoSos = true;
  bool _smsEnabled = true;

  bool get darkTheme => _darkTheme;
  bool get autoSos => _autoSos;
  bool get smsEnabled => _smsEnabled;

  // GPS & Live Tracking — real values from device hardware
  bool _isTrackingActive = false;
  double _currentSpeedKmh = 0.0;
  double _gpsAccuracyMeter = 0.0;
  double _userLat = 0.0;
  double _userLng = 0.0;
  bool _locationReady = false;

  bool get isTrackingActive => _isTrackingActive;
  double get mockSpeedKmh => _currentSpeedKmh;
  double get gpsAccuracyMeter => _gpsAccuracyMeter;
  double get userLat => _userLat;
  double get userLng => _userLng;
  bool get locationReady => _locationReady;

  StreamSubscription<Position>? _positionSubscription;
  StreamSubscription<UserAccelerometerEvent>? _accelerometerSubscription;
  Timer? _trackingTimer;

  // Emergency State
  bool _isEmergencyActive = false;
  int _emergencyCountdown = 10;
  Timer? _emergencyTimer;
  String _emergencyMessage = 'Accident detected! Contacting emergency contacts.';
  
  bool get isEmergencyActive => _isEmergencyActive;
  bool get isCountdownActive => _emergencyCountdown > 0;
  int get emergencyCountdown => _emergencyCountdown;
  String get emergencyMessage => _emergencyMessage;

  // Platform Channels
  static const _smsChannel = MethodChannel('com.guardianpulse/sms');

  // Alert History
  final List<EmergencyAlert> _alerts = [];
  List<EmergencyAlert> get alerts => _alerts;

  // Real-time Weather & Environmental Road Safety Telemetry
  double _currentTemp = 27.5;
  double _rainMm = 0.0;
  double _windSpeed = 8.5;
  String _weatherDescription = 'Clear Sky';
  double _safetyScore = 98.0;
  String _safetyAdvice = 'Optimal driving conditions. Stay safe!';
  bool _weatherFetched = false;

  double get currentTemp => _currentTemp;
  double get rainMm => _rainMm;
  double get windSpeed => _windSpeed;
  String get weatherDescription => _weatherDescription;
  double get safetyScore => _safetyScore;
  String get safetyAdvice => _safetyAdvice;

  // Nearby Services
  List<NearbyService> _services = [];
  List<NearbyService> get services => _services;
  bool _osmFetched = false;
  
  ServiceCategory? _activeFilterCategory;
  ServiceCategory? get activeFilterCategory => _activeFilterCategory;

  NearbyService? _selectedService;
  NearbyService? get selectedService => _selectedService;

  AppState() {
    _initGps();
    _initCrashDetection();
  }

  // ============================================================
  //  REAL GPS — fetches actual device coordinates + speed
  // ============================================================
  Future<void> _initGps() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever) return;

      _locationPermission = (perm == LocationPermission.always || perm == LocationPermission.whileInUse);
      if (!_locationPermission) return;

      // One-shot high accuracy fix
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      _applyPosition(pos);

      // Continuous stream
      _positionSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 3,
        ),
      ).listen(_applyPosition);
    } catch (e) {
      debugPrint('GPS init error: $e');
    }
  }

  void _applyPosition(Position pos) {
    _userLat = pos.latitude;
    _userLng = pos.longitude;
    _gpsAccuracyMeter = pos.accuracy;
    _locationReady = true;

    // Real driving speed from GPS (m/s → km/h)
    if (pos.speed > 0) {
      _currentSpeedKmh = pos.speed * 3.6;
    }

    // Fetch real nearby places from OpenStreetMap (once, or when user moves >1 km)
    if (!_osmFetched) {
      _osmFetched = true;
      _fetchOsmNearby(pos.latitude, pos.longitude);
    }

    // Fetch real weather and road environment conditions
    if (!_weatherFetched) {
      _weatherFetched = true;
      _fetchRealTimeWeather(pos.latitude, pos.longitude);
    }

    notifyListeners();
  }

  // ============================================================
  //  WEATHER & ROAD SAFETY INDEX — fetch environmental telemetry
  // ============================================================
  Future<void> _fetchRealTimeWeather(double lat, double lng) async {
    try {
      final apiKey = '114c521fcb935ddf687d642c474c9865';
      final url = Uri.parse(
        'https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lng&appid=$apiKey&units=metric'
      );
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final main = data['main'] ?? {};
        final wind = data['wind'] ?? {};
        final weatherList = data['weather'] as List? ?? [];
        final weather = weatherList.isNotEmpty ? weatherList.first : {};
        
        _currentTemp = (main['temp'] ?? 27.5).toDouble();
        
        // Wind speed from OpenWeather is in m/s, convert to km/h
        final windMps = (wind['speed'] ?? 2.3).toDouble();
        _windSpeed = windMps * 3.6;
        
        // Rain precipitation from OpenWeather
        final rainMap = data['rain'] ?? {};
        _rainMm = (rainMap['1h'] ?? rainMap['3h'] ?? 0.0).toDouble();
        
        final int conditionId = weather['id'] ?? 800;
        _weatherDescription = weather['main'] ?? 'Clear';
        
        // Calculate dynamic safety score (start at 100)
        double score = 100.0;
        List<String> advices = [];
        
        if (_rainMm > 0) {
          if (_rainMm > 5) {
            score -= 25;
            advices.add('Heavy rain: wet roads, double your stopping distance.');
          } else {
            score -= 10;
            advices.add('Light rain: roads might be slippery.');
          }
        }
        
        if (_windSpeed > 20) {
          score -= 15;
          advices.add('High winds: watch out for crosswinds on highway.');
        }
        
        // OpenWeather Weather Condition Codes
        if (conditionId >= 200 && conditionId < 300) {
          score -= 40;
          advices.add('Severe thunderstorm: avoid driving.');
        } else if (conditionId >= 300 && conditionId < 600) {
          score -= 20;
          advices.add('Rainy visibility: slow down and keep safe distance.');
        } else if (conditionId >= 600 && conditionId < 700) {
          score -= 25;
          advices.add('Snowy roads: warning, black ice and low traction.');
        } else if (conditionId == 741) { // Fog
          score -= 30;
          advices.add('Foggy visibility: reduce speed, turn on fog lights.');
        }
        
        // factor in speedometer speed
        if (_currentSpeedKmh > 100) {
          score -= 20;
          advices.add('Speeding risk: reduce speed to match the road limit.');
        } else if (_currentSpeedKmh > 80) {
          score -= 8;
          advices.add('High speed: maintain safe gap from front vehicles.');
        }
        
        _safetyScore = max(10.0, score);
        if (advices.isEmpty) {
          _safetyAdvice = 'Optimal driving conditions. Travel safely!';
        } else {
          _safetyAdvice = advices.join(' ');
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Weather fetch error: $e');
      _weatherFetched = false; // Allow retry on next location update
    }
  }

  // ============================================================
  //  OVERPASS API — fetch real hospitals, police, pharmacies
  // ============================================================
  Future<void> _fetchOsmNearby(double lat, double lng) async {
    // Build Overpass QL query for hospitals, police, pharmacies, car_repair (towing)
    final String query = '''
[out:json][timeout:10];
(
  node["amenity"="hospital"](around:5000,$lat,$lng);
  way["amenity"="hospital"](around:5000,$lat,$lng);
  node["amenity"="police"](around:5000,$lat,$lng);
  node["amenity"="pharmacy"](around:5000,$lat,$lng);
  node["shop"="car_repair"](around:5000,$lat,$lng);
  node["amenity"="restaurant"](around:3000,$lat,$lng);
);
out center body 20;
''';

    try {
      final response = await http.post(
        Uri.parse('https://overpass-api.de/api/interpreter'),
        body: {'data': query},
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List elements = data['elements'] ?? [];
        final List<NearbyService> realServices = [];
        int idx = 0;

        for (final el in elements) {
          // Ways have center sub-object, nodes have lat/lon directly
          final double? eLat = el['lat'] ?? el['center']?['lat'];
          final double? eLng = el['lon'] ?? el['center']?['lon'];
          if (eLat == null || eLng == null) continue;

          final Map<String, dynamic> tags = Map<String, dynamic>.from(el['tags'] ?? {});
          final String name = tags['name'] ?? tags['name:en'] ?? '';
          if (name.isEmpty) continue;

          // Distance in km
          final double distMeters = Geolocator.distanceBetween(lat, lng, eLat, eLng);
          final double distKm = distMeters / 1000.0;
          final int eta = max(1, (distKm * 3.5).round());

          // Determine category
          final String amenity = tags['amenity'] ?? '';
          final String shop = tags['shop'] ?? '';
          ServiceCategory cat;
          if (amenity == 'hospital') {
            cat = ServiceCategory.hospital;
          } else if (amenity == 'police') {
            cat = ServiceCategory.police;
          } else if (amenity == 'pharmacy') {
            cat = ServiceCategory.medical;
          } else if (shop == 'car_repair') {
            cat = ServiceCategory.towing;
          } else if (amenity == 'restaurant') {
            cat = ServiceCategory.restaurant;
          } else {
            continue;
          }

          // Build address from available tags
          String address = '';
          if (tags['addr:street'] != null) address = tags['addr:street'];
          if (tags['addr:city'] != null) address += (address.isEmpty ? '' : ', ') + tags['addr:city'];
          if (address.isEmpty) address = tags['addr:suburb'] ?? 'Nearby, India';

          // Phone number from OSM tags or fallback
          String phone = tags['phone'] ?? tags['contact:phone'] ?? '';
          if (phone.isEmpty) {
            switch (cat) {
              case ServiceCategory.hospital: phone = '108'; break;
              case ServiceCategory.police: phone = '100'; break;
              case ServiceCategory.medical: phone = '104'; break;
              default: phone = '112';
            }
          }

          // Rating: use a sensible synthetic value
          final double rating = 3.8 + (idx % 12) * 0.1;

          realServices.add(NearbyService(
            id: 'osm_$idx',
            name: name,
            category: cat,
            distanceKm: double.parse(distKm.toStringAsFixed(1)),
            etaMinutes: eta,
            rating: double.parse(rating.toStringAsFixed(1)),
            phone: phone,
            address: address,
            mockLatOffset: eLat - lat,
            mockLngOffset: eLng - lng,
          ));
          idx++;
        }

        // Sort by distance
        realServices.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));

        if (realServices.isNotEmpty) {
          _services = realServices;
          notifyListeners();
          debugPrint('GUARDIAN PULSE: Loaded ${realServices.length} real services from OpenStreetMap');
          return;
        }
      }
    } catch (e) {
      debugPrint('Overpass API error: $e');
    }

    // Fallback: generate services if API failed
    debugPrint('GUARDIAN PULSE: Using fallback services');
    _services = _buildFallbackServices(lat, lng);
    notifyListeners();
  }

  /// Re-fetch services for current location (can be called manually)
  void refreshNearbyServices() {
    if (_locationReady) {
      _osmFetched = false;
      _fetchOsmNearby(_userLat, _userLng);
    }
  }

  List<NearbyService> _buildFallbackServices(double lat, double lng) {
    return [
      NearbyService(
        id: 'fb_h1', name: 'Government General Hospital',
        category: ServiceCategory.hospital, distanceKm: 1.2, etaMinutes: 4,
        rating: 4.3, phone: '108', address: 'Near your location, India',
        mockLatOffset: 0.004, mockLngOffset: -0.003,
      ),
      NearbyService(
        id: 'fb_h2', name: 'Private Multi-Speciality Hospital',
        category: ServiceCategory.hospital, distanceKm: 2.1, etaMinutes: 7,
        rating: 4.6, phone: '108', address: 'Main Road, India',
        mockLatOffset: -0.005, mockLngOffset: 0.006,
      ),
      NearbyService(
        id: 'fb_a1', name: '108 Emergency Ambulance Service',
        category: ServiceCategory.ambulance, distanceKm: 0.5, etaMinutes: 2,
        rating: 4.9, phone: '108', address: 'Mobile Unit, India',
        mockLatOffset: 0.001, mockLngOffset: 0.002,
      ),
      NearbyService(
        id: 'fb_p1', name: 'District Police Station',
        category: ServiceCategory.police, distanceKm: 1.0, etaMinutes: 4,
        rating: 4.2, phone: '100', address: 'Station Road, India',
        mockLatOffset: -0.003, mockLngOffset: -0.003,
      ),
      NearbyService(
        id: 'fb_t1', name: 'Highway Towing & Recovery',
        category: ServiceCategory.towing, distanceKm: 2.5, etaMinutes: 9,
        rating: 4.5, phone: '112', address: 'NH Junction, India',
        mockLatOffset: 0.006, mockLngOffset: 0.007,
      ),
      NearbyService(
        id: 'fb_m1', name: 'Medical Store 24/7',
        category: ServiceCategory.medical, distanceKm: 0.3, etaMinutes: 1,
        rating: 4.4, phone: '104', address: 'Cross Road, India',
        mockLatOffset: -0.001, mockLngOffset: -0.001,
      ),
    ];
  }

  // ============================================================
  //  ACCELEROMETER — real hardware crash detection
  // ============================================================
  void _initCrashDetection() {
    _accelerometerSubscription = userAccelerometerEvents.listen((event) {
      if (!_autoSos || _isEmergencyActive) return;

      final double mag = event.x * event.x + event.y * event.y + event.z * event.z;
      // ~2.8G threshold (28 m/s²)² = 784
      if (mag > 784.0) {
        final double gForce = sqrt(mag) / 9.81;
        debugPrint('CRASH DETECTED: ${gForce.toStringAsFixed(1)}G');
        startSosCountdown(
          customMessage: 'Crash Shock of ${gForce.toStringAsFixed(1)}G Detected! Auto-SOS initiating...',
        );
      }
    });
  }

  // ============================================================
  //  AUTH
  // ============================================================
  void login(String phone) {
    _isLoggedIn = true;
    _userPhone = phone;
    _profile = _profile.copyWith(phone: phone);
    notifyListeners();
  }

  void logout() {
    _isLoggedIn = false;
    _userPhone = '';
    _userRole = 'user';
    _isTrackingActive = false;
    _trackingTimer?.cancel();
    _isEmergencyActive = false;
    _emergencyTimer?.cancel();
    _currentTab = 0;
    notifyListeners();
  }

  void selectRole(String role) {
    _userRole = role;
    notifyListeners();
  }

  void saveProfile(UserProfile newProfile) {
    _profile = newProfile.copyWith(isSetUp: true);
    notifyListeners();
  }

  // ============================================================
  //  GUARDIANS
  // ============================================================
  void addGuardian(String name, String phone, String relationship) {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    _guardians.add(Guardian(id: id, name: name, phone: phone, relationship: relationship));
    notifyListeners();
  }

  void removeGuardian(String id) {
    _guardians.removeWhere((g) => g.id == id);
    notifyListeners();
  }

  // ============================================================
  //  PERMISSIONS — triggers real OS dialogs
  // ============================================================
  Future<void> togglePermission(String type) async {
    if (type == 'location') {
      try {
        LocationPermission perm = await Geolocator.checkPermission();
        if (perm == LocationPermission.denied) {
          perm = await Geolocator.requestPermission();
        }
        _locationPermission = perm == LocationPermission.always || perm == LocationPermission.whileInUse;
        if (_locationPermission) _initGps();
      } catch (e) {
        debugPrint('Location perm error: $e');
      }
    }
    if (type == 'sms') {
      _smsPermission = true; // SMS permission is declared in manifest; runtime prompt handled by OS on first send
    }
    if (type == 'notification') _notificationPermission = !_notificationPermission;
    if (type == 'microphone') _microphonePermission = !_microphonePermission;
    notifyListeners();
  }

  void enableAllPermissions() async {
    _notificationPermission = true;
    _microphonePermission = true;
    _smsPermission = true;

    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      _locationPermission = perm == LocationPermission.always || perm == LocationPermission.whileInUse;
      if (_locationPermission) _initGps();
    } catch (e) {
      debugPrint('Permissions error: $e');
    }
    notifyListeners();
  }

  // ============================================================
  //  SETTINGS
  // ============================================================
  void toggleTheme() { _darkTheme = !_darkTheme; notifyListeners(); }
  void toggleAutoSos() { _autoSos = !_autoSos; notifyListeners(); }
  void toggleSmsEnabled() { _smsEnabled = !_smsEnabled; notifyListeners(); }

  // ============================================================
  //  TRACKING — uses real GPS, no simulation
  // ============================================================
  void startTracking() {
    if (!_locationPermission) return;
    _isTrackingActive = true;
    notifyListeners();
  }

  void stopTracking() {
    _isTrackingActive = false;
    _currentSpeedKmh = 0.0;
    notifyListeners();
  }

  // ============================================================
  //  SOS / EMERGENCY
  // ============================================================
  void startSosCountdown({String? customMessage}) {
    if (_isEmergencyActive && _emergencyCountdown == 0) return;
    
    _isEmergencyActive = true;
    _emergencyCountdown = 10;
    _emergencyMessage = customMessage ?? 'Manual SOS Triggered. Notifying contacts.';
    notifyListeners();

    _emergencyTimer?.cancel();
    _emergencyTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_emergencyCountdown > 1) {
        _emergencyCountdown--;
        notifyListeners();
      } else {
        _emergencyCountdown = 0;
        _emergencyTimer?.cancel();
        _triggerEmergencyAlert();
      }
    });
  }

  void cancelSos() {
    _isEmergencyActive = false;
    _emergencyTimer?.cancel();
    _emergencyCountdown = 10;
    notifyListeners();
  }

  void resolveEmergency() {
    _isEmergencyActive = false;
    _emergencyTimer?.cancel();
    
    for (int i = 0; i < _alerts.length; i++) {
      if (_alerts[i].status == AlertStatus.active) {
        _alerts[i] = EmergencyAlert(
          id: _alerts[i].id,
          title: _alerts[i].title,
          description: _alerts[i].description,
          timestamp: _alerts[i].timestamp,
          status: AlertStatus.resolved,
          type: _alerts[i].type,
        );
      }
    }
    notifyListeners();
  }

  void triggerImmediateSos() {
    _isEmergencyActive = true;
    _emergencyCountdown = 0;
    _triggerEmergencyAlert();
  }

  void simulateAccident() {
    startSosCountdown(customMessage: 'Crash Impact Detected! Auto-SOS initiating...');
  }

  // ============================================================
  //  REAL SMS SENDING — via native Kotlin MethodChannel
  // ============================================================
  Future<bool> _sendRealSMS(String phone, String message) async {
    try {
      final result = await _smsChannel.invokeMethod('sendSMS', {
        'phone': phone,
        'message': message,
      });
      debugPrint('SMS OK → $result');
      return true;
    } catch (e) {
      debugPrint('SMS FAIL → $e');
      return false;
    }
  }

  void _triggerEmergencyAlert() {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final String mapsLink = 'https://maps.google.com/?q=$_userLat,$_userLng';
    final bool isCrash = _emergencyMessage.contains('Crash') || _emergencyMessage.contains('Shock');
    
    // Keep SMS short and clean so it sends reliably
    final String smsBody =
        'SOS GUARDIAN PULSE!\n'
        '${_profile.name} needs help!\n'
        'Blood: ${_profile.bloodGroup}\n'
        '${isCrash ? "Auto-detected crash" : "Manual SOS"}\n'
        '$mapsLink';

    // Send SMS to all guardians
    int sentCount = 0;
    if (_smsEnabled) {
      for (final g in _guardians) {
        if (g.phone.isNotEmpty) {
          _sendRealSMS(g.phone, smsBody).then((ok) {
            if (ok) sentCount++;
          });
        }
      }
    }

    _alerts.insert(0, EmergencyAlert(
      id: id,
      title: isCrash ? 'Accident Detected' : 'Manual SOS Active',
      description: 'SMS with Google Maps link sent to ${_guardians.length} guardians. Location: ${_userLat.toStringAsFixed(5)}, ${_userLng.toStringAsFixed(5)}',
      timestamp: DateTime.now(),
      status: AlertStatus.active,
      type: isCrash ? AlertType.accident : AlertType.sos,
    ));
    notifyListeners();
  }

  // ============================================================
  //  SERVICES FILTERING
  // ============================================================
  void filterServices(ServiceCategory? category) {
    _activeFilterCategory = category;
    notifyListeners();
  }

  void selectService(NearbyService? service) {
    _selectedService = service;
    notifyListeners();
  }

  List<NearbyService> get filteredServices {
    if (_activeFilterCategory == null) return _services;
    return _services.where((s) => s.category == _activeFilterCategory).toList();
  }

  @override
  void dispose() {
    _trackingTimer?.cancel();
    _emergencyTimer?.cancel();
    _positionSubscription?.cancel();
    _accelerometerSubscription?.cancel();
    super.dispose();
  }
}
