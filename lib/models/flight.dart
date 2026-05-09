class Flight {
  final String icao24;
  final String? callsign;
  final String? originCountry;
  final double? longitude;
  final double? latitude;
  final double? baroAltitude;
  final double? velocity;
  final double? trueTrack;
  final double? verticalRate;
  final bool onGround;
  final int? lastContact;
  final double? geoAltitude;

  const Flight({
    required this.icao24,
    this.callsign,
    this.originCountry,
    this.longitude,
    this.latitude,
    this.baroAltitude,
    this.velocity,
    this.trueTrack,
    this.verticalRate,
    required this.onGround,
    this.lastContact,
    this.geoAltitude,
  });

  factory Flight.fromStateVector(List<dynamic> state) {
    return Flight(
      icao24: state[0] as String? ?? '',
      callsign: (state[1] as String?)?.trim(),
      originCountry: state[2] as String?,
      lastContact: state[4] as int?,
      longitude: (state[5] as num?)?.toDouble(),
      latitude: (state[6] as num?)?.toDouble(),
      baroAltitude: (state[7] as num?)?.toDouble(),
      onGround: state[8] as bool? ?? false,
      velocity: (state[9] as num?)?.toDouble(),
      trueTrack: (state[10] as num?)?.toDouble(),
      verticalRate: (state[11] as num?)?.toDouble(),
      geoAltitude: (state[13] as num?)?.toDouble(),
    );
  }

  bool get hasPosition => latitude != null && longitude != null;

  String get displayCallsign => (callsign?.isNotEmpty == true) ? callsign! : icao24.toUpperCase();

  String get altitudeDisplay {
    if (baroAltitude == null) return 'N/A';
    return '${(baroAltitude! * 3.28084).round()} ft';
  }

  String get speedDisplay {
    if (velocity == null) return 'N/A';
    return '${(velocity! * 1.94384).round()} kts';
  }

  String get flightStatus {
    if (onGround) return 'GROUND';
    if (baroAltitude != null && baroAltitude! > 10000) return 'CRUISE';
    if (verticalRate != null && verticalRate! > 2) return 'CLIMB';
    if (verticalRate != null && verticalRate! < -2) return 'DESCEND';
    return 'LEVEL';
  }

  ThreatLevel get threatLevel {
    if (onGround) return ThreatLevel.none;
    if (baroAltitude != null && baroAltitude! < 300) return ThreatLevel.high;
    if (baroAltitude != null && baroAltitude! < 1000) return ThreatLevel.medium;
    return ThreatLevel.low;
  }
}

enum ThreatLevel { none, low, medium, high }
