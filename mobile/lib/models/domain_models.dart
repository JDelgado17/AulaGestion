class AppUser {
  const AppUser(
      {required this.id,
      required this.name,
      required this.email,
      required this.role,
      required this.isActive});

  final int id;
  final String name;
  final String email;
  final String role;
  final bool isActive;

  String get roleLabel => switch (role) {
        'admin' => 'Administrador',
        'inventory' => 'Encargado de inventario',
        _ => 'Profesor',
      };

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: _asInt(json['id']),
        name: json['name']?.toString() ?? '',
        email: json['email']?.toString() ?? '',
        role: json['role']?.toString() ?? 'professor',
        isActive: json['is_active'] == true || json['is_active'] == 1,
      );
}

class InventoryItem {
  const InventoryItem({
    required this.id,
    required this.classroomId,
    required this.name,
    required this.category,
    required this.quantity,
    required this.availableQuantity,
    required this.status,
    this.description,
    this.classroom,
  });

  final int id;
  final int classroomId;
  final String name;
  final String category;
  final int quantity;
  final int availableQuantity;
  final String status;
  final String? description;
  final Map<String, dynamic>? classroom;

  factory InventoryItem.fromJson(Map<String, dynamic> json) => InventoryItem(
        id: _asInt(json['id']),
        classroomId: _asInt(json['classroom_id']),
        name: json['name']?.toString() ?? '',
        category: json['category']?.toString() ?? '',
        quantity: _asInt(json['quantity']),
        availableQuantity: _asInt(json['available_quantity']),
        status: json['status']?.toString() ?? '',
        description: json['description']?.toString(),
        classroom: json['classroom'] is Map
            ? Map<String, dynamic>.from(json['classroom'])
            : null,
      );
}

class Classroom {
  const Classroom({
    required this.id,
    required this.code,
    required this.name,
    required this.location,
    required this.capacity,
    required this.type,
    required this.status,
    required this.isActive,
    this.description,
    this.inventory = const [],
  });

  final int id;
  final String code;
  final String name;
  final String location;
  final int capacity;
  final String type;
  final String status;
  final bool isActive;
  final String? description;
  final List<InventoryItem> inventory;

  factory Classroom.fromJson(Map<String, dynamic> json) => Classroom(
        id: _asInt(json['id']),
        code: json['code']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        location: json['location']?.toString() ?? '',
        capacity: _asInt(json['capacity']),
        type: json['type']?.toString() ?? '',
        status: json['status']?.toString() ?? 'available',
        isActive: json['is_active'] == true || json['is_active'] == 1,
        description: json['description']?.toString(),
        inventory: (json['inventory_items'] as List? ?? [])
            .whereType<Map>()
            .map((item) =>
                InventoryItem.fromJson(Map<String, dynamic>.from(item)))
            .toList(),
      );
}

class RoomRecommendation {
  const RoomRecommendation({
    required this.classroom,
    required this.matchPercent,
    required this.matchLevel,
    required this.isExactMatch,
    required this.reasons,
    required this.missingResources,
  });

  final Classroom classroom;
  final int matchPercent;
  final String matchLevel;
  final bool isExactMatch;
  final List<String> reasons;
  final List<String> missingResources;

  factory RoomRecommendation.fromJson(Map<String, dynamic> json) =>
      RoomRecommendation(
        classroom: Classroom.fromJson(
            Map<String, dynamic>.from(json['classroom'] as Map)),
        matchPercent: _asInt(json['match_percent']),
        matchLevel: json['match_level']?.toString() ?? '',
        isExactMatch: json['is_exact_match'] == true,
        reasons: (json['reasons'] as List? ?? [])
            .map((item) => item.toString())
            .toList(),
        missingResources: (json['missing_resources'] as List? ?? [])
            .map((item) => item.toString())
            .toList(),
      );
}

class Reservation {
  const Reservation({
    required this.id,
    required this.startsAt,
    required this.endsAt,
    required this.attendees,
    required this.activityType,
    required this.purpose,
    required this.status,
    this.classroom,
    this.user,
    this.cancellationReason,
  });

  final int id;
  final DateTime startsAt;
  final DateTime endsAt;
  final int attendees;
  final String activityType;
  final String purpose;
  final String status;
  final Classroom? classroom;
  final AppUser? user;
  final String? cancellationReason;

  factory Reservation.fromJson(Map<String, dynamic> json) => Reservation(
        id: _asInt(json['id']),
        startsAt: DateTime.parse(json['starts_at'].toString()).toLocal(),
        endsAt: DateTime.parse(json['ends_at'].toString()).toLocal(),
        attendees: _asInt(json['attendees']),
        activityType: json['activity_type']?.toString() ?? '',
        purpose: json['purpose']?.toString() ?? '',
        status: json['status']?.toString() ?? '',
        classroom: json['classroom'] is Map
            ? Classroom.fromJson(Map<String, dynamic>.from(json['classroom']))
            : null,
        user: json['user'] is Map
            ? AppUser.fromJson({
                ...Map<String, dynamic>.from(json['user']),
                'is_active': true,
                'role': json['user']['role'] ?? 'professor'
              })
            : null,
        cancellationReason: json['cancellation_reason']?.toString(),
      );
}

int _asInt(dynamic value) =>
    value is int ? value : int.tryParse(value?.toString() ?? '') ?? 0;
