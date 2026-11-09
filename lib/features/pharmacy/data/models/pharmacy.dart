import 'dart:convert';

/// Modèle représentant une pharmacie gérée par un pharmacien.
///
/// Une pharmacie appartient à un seul pharmacien (relation 1:1 via [pharmacienUserId]).
/// Elle contient les informations de localisation, contact, et horaires d'ouverture.
class Pharmacy {
  const Pharmacy({
    this.pharmacyId,
    required this.pharmacienUserId,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.phone,
    this.email,
    this.photoUrl,
    this.openingHours,
    required this.createdAt,
    required this.updatedAt,
  });

  final int? pharmacyId;
  final int pharmacienUserId;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final String? phone;
  final String? email;
  final String? photoUrl;
  final Map<String, String>? openingHours; // {"monday":"08:00-18:00", "tuesday":"08:00-18:00", ...}
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Crée une instance depuis une ligne de la base de données.
  factory Pharmacy.fromMap(Map<String, dynamic> map) {
    Map<String, String>? hours;
    if (map['opening_hours'] != null && map['opening_hours'] is String) {
      try {
        final decoded = jsonDecode(map['opening_hours'] as String);
        hours = Map<String, String>.from(decoded as Map);
      } catch (_) {
        hours = null;
      }
    }

    return Pharmacy(
      pharmacyId: map['pharmacy_id'] as int?,
      pharmacienUserId: map['pharmacien_user_id'] as int,
      name: map['name'] as String,
      address: map['address'] as String,
      latitude: map['latitude'] as double,
      longitude: map['longitude'] as double,
      phone: map['phone'] as String?,
      email: map['email'] as String?,
      photoUrl: map['photo_url'] as String?,
      openingHours: hours,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  /// Convertit vers un Map pour insertion/mise à jour dans SQLite.
  Map<String, dynamic> toMap() {
    return {
      if (pharmacyId != null) 'pharmacy_id': pharmacyId,
      'pharmacien_user_id': pharmacienUserId,
      'name': name,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'phone': phone,
      'email': email,
      'photo_url': photoUrl,
      'opening_hours': openingHours != null ? jsonEncode(openingHours) : null,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Copie avec modifications.
  Pharmacy copyWith({
    int? pharmacyId,
    int? pharmacienUserId,
    String? name,
    String? address,
    double? latitude,
    double? longitude,
    String? phone,
    String? email,
    String? photoUrl,
    Map<String, String>? openingHours,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Pharmacy(
      pharmacyId: pharmacyId ?? this.pharmacyId,
      pharmacienUserId: pharmacienUserId ?? this.pharmacienUserId,
      name: name ?? this.name,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      openingHours: openingHours ?? this.openingHours,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Retourne les horaires du jour spécifié (e.g., "monday", "tuesday").
  String? getHoursForDay(String day) {
    return openingHours?[day.toLowerCase()];
  }

  /// Indique s'il s'agit d'une pharmacie de nuit.
  bool get isNightPharmacy {
    if (name.toLowerCase().contains('nuit')) return true;
    final hours = openingHours;
    if (hours != null) {
      for (final h in hours.values) {
        if (_isOvernightRange(h)) return true;
      }
    }
    return false;
  }

  /// Vérifie si la pharmacie est ouverte en ce moment précis selon l'heure et le jour actuels.
  bool get isOpenNow {
    return isPharmacyOpenAt(DateTime.now());
  }

  /// Détermine si la pharmacie est ouverte à un moment précis.
  bool isPharmacyOpenAt(DateTime dateTime) {
    if (openingHours == null || openingHours!.isEmpty) {
      final timeMinutes = dateTime.hour * 60 + dateTime.minute;
      if (isNightPharmacy) {
        return timeMinutes >= (19 * 60 + 30) || timeMinutes <= (8 * 60 + 30);
      }
      return timeMinutes >= (8 * 60) && timeMinutes <= (19 * 60 + 30);
    }

    const days = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
    final currentDay = days[dateTime.weekday - 1];
    final currentHours = openingHours![currentDay];
    final currentTotalMinutes = dateTime.hour * 60 + dateTime.minute;

    // 1. Horaires du jour
    if (currentHours != null && currentHours.toLowerCase() != 'fermé' && currentHours.isNotEmpty) {
      if (_matchesSchedule(currentHours, currentTotalMinutes)) {
        return true;
      }
    }

    // 2. Débordement éventuel de la nuit précédente le matin avant 12h
    if (currentTotalMinutes < 12 * 60) {
      final yesterdayWeekday = dateTime.weekday == 1 ? 7 : dateTime.weekday - 1;
      final yesterday = days[yesterdayWeekday - 1];
      final yesterdayHours = openingHours![yesterday];
      if (yesterdayHours != null && yesterdayHours.toLowerCase() != 'fermé' && yesterdayHours.isNotEmpty) {
        if (_isOvernightRange(yesterdayHours)) {
          final endMinutes = _getRangeEndMinutes(yesterdayHours);
          if (currentTotalMinutes <= endMinutes) {
            return true;
          }
        }
      }
    }

    return false;
  }

  static bool _isOvernightRange(String schedule) {
    final parts = schedule.split('-');
    if (parts.length != 2) return false;
    final start = _parseMinutes(parts[0]);
    final end = _parseMinutes(parts[1]);
    if (start == null || end == null) return false;
    return start > end;
  }

  static int _getRangeEndMinutes(String schedule) {
    final parts = schedule.split('-');
    if (parts.length != 2) return 0;
    return _parseMinutes(parts[1]) ?? 0;
  }

  static bool _matchesSchedule(String schedule, int nowMinutes) {
    if (schedule.toLowerCase().contains('24h')) return true;
    final parts = schedule.split('-');
    if (parts.length != 2) return false;
    final start = _parseMinutes(parts[0]);
    final end = _parseMinutes(parts[1]);
    if (start == null || end == null) return false;

    if (start > end) {
      // Plage nocturne (ex: 19:30 - 08:30)
      return nowMinutes >= start || nowMinutes <= end;
    } else {
      // Plage diurne (ex: 08:00 - 19:30)
      return nowMinutes >= start && nowMinutes <= end;
    }
  }

  static int? _parseMinutes(String timeStr) {
    final clean = timeStr.trim().replaceAll('h', ':');
    final segments = clean.split(':');
    if (segments.length != 2) return null;
    final h = int.tryParse(segments[0]);
    final m = int.tryParse(segments[1]);
    if (h == null || m == null) return null;
    return h * 60 + m;
  }

  /// Libellé d'état court pour affichage UI
  String get statusDisplay {
    final open = isOpenNow;
    if (open) {
      if (isNightPharmacy) {
        return 'Ouvert (Garde de Nuit)';
      }
      return 'Ouvert actuellement';
    } else {
      if (isNightPharmacy) {
        return 'Fermé • Ouvre à 19:30 (Nuit)';
      }
      return 'Fermé actuellement';
    }
  }

  /// Horaires formatés d'aujourd'hui
  String get todayHoursDisplay {
    final now = DateTime.now();
    const days = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
    final today = days[now.weekday - 1];
    return openingHours?[today] ?? (isNightPharmacy ? '19:30 - 08:30' : '08:00 - 19:30');
  }

  /// Vérifie si la pharmacie est ouverte aujourd'hui.
  bool get isOpenToday {
    final now = DateTime.now();
    const days = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
    final today = days[now.weekday - 1];
    final hours = getHoursForDay(today);
    return hours != null && hours.toLowerCase() != 'fermé' && hours.isNotEmpty;
  }

  @override
  String toString() {
    return 'Pharmacy(id: $pharmacyId, name: $name, address: $address, lat: $latitude, lon: $longitude)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Pharmacy && other.pharmacyId == pharmacyId;
  }

  @override
  int get hashCode => pharmacyId.hashCode;
}
