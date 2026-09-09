import '../core/api_client.dart';
import '../models/domain_models.dart';

class SchoolRepository {
  const SchoolRepository(this.client);

  final ApiClient client;

  Future<Map<String, dynamic>> dashboard() async => Map<String, dynamic>.from(await client.get('/dashboard'));

  Future<List<Classroom>> classrooms({String? search, String? status}) async {
    final raw = await client.get('/classrooms', query: {
      'active_only': true,
      if (search?.isNotEmpty == true) 'search': search,
      if (status?.isNotEmpty == true) 'status': status,
    });
    return _records(raw).map(Classroom.fromJson).toList();
  }

  Future<Classroom> classroom(int id) async => Classroom.fromJson(Map<String, dynamic>.from(await client.get('/classrooms/$id')));

  Future<Classroom> saveClassroom(Map<String, dynamic> data, {int? id}) async {
    final raw = id == null ? await client.post('/classrooms', body: data) : await client.put('/classrooms/$id', body: data);
    return Classroom.fromJson(Map<String, dynamic>.from(raw));
  }

  Future<void> disableClassroom(int id) => client.delete('/classrooms/$id');

  Future<List<AppUser>> users({String? search}) async {
    final raw = await client.get('/users', query: {if (search?.isNotEmpty == true) 'search': search});
    return _records(raw).map(AppUser.fromJson).toList();
  }

  Future<AppUser> saveUser(Map<String, dynamic> data, {int? id}) async {
    final raw = id == null ? await client.post('/users', body: data) : await client.put('/users/$id', body: data);
    return AppUser.fromJson(Map<String, dynamic>.from(raw));
  }

  Future<void> disableUser(int id) => client.delete('/users/$id');

  Future<List<InventoryItem>> inventory({int? classroomId, String? status}) async {
    final raw = await client.get('/inventory', query: {
      if (classroomId != null) 'classroom_id': classroomId,
      if (status?.isNotEmpty == true) 'status': status,
    });
    return _records(raw).map(InventoryItem.fromJson).toList();
  }

  Future<InventoryItem> saveInventory(Map<String, dynamic> data, {int? id}) async {
    final raw = id == null ? await client.post('/inventory', body: data) : await client.put('/inventory/$id', body: data);
    return InventoryItem.fromJson(Map<String, dynamic>.from(raw));
  }

  Future<Map<String, dynamic>> addInventoryEvent(int itemId, Map<String, dynamic> data) async {
    return Map<String, dynamic>.from(await client.post('/inventory/$itemId/events', body: data));
  }

  Future<List<Map<String, dynamic>>> inventoryEvents({int? classroomId}) async {
    final raw = await client.get('/inventory-events', query: {if (classroomId != null) 'classroom_id': classroomId});
    return _records(raw);
  }

  Future<Map<String, dynamic>> recommendations(Map<String, dynamic> criteria) async {
    return Map<String, dynamic>.from(await client.post('/recommendations/search', body: criteria));
  }

  Future<List<Reservation>> reservations({String? status, DateTime? from, DateTime? to}) async {
    final raw = await client.get('/reservations', query: {
      if (status?.isNotEmpty == true) 'status': status,
      if (from != null) 'from': from.toIso8601String(),
      if (to != null) 'to': to.toIso8601String(),
    });
    return _records(raw).map(Reservation.fromJson).toList();
  }

  Future<Reservation> createReservation(Map<String, dynamic> data) async {
    return Reservation.fromJson(Map<String, dynamic>.from(await client.post('/reservations', body: data)));
  }

  Future<Reservation> cancelReservation(int id, String reason) async {
    return Reservation.fromJson(Map<String, dynamic>.from(await client.patch('/reservations/$id/cancel', body: {'reason': reason})));
  }

  Future<List<Map<String, dynamic>>> notifications() async => _records(await client.get('/notifications'));

  Future<void> markNotificationRead(int id) => client.patch('/notifications/$id/read');

  Future<void> markAllNotificationsRead() => client.patch('/notifications/read-all');

  Future<List<Map<String, dynamic>>> schedules({int? classroomId}) async {
    final raw = await client.get('/schedules', query: {if (classroomId != null) 'classroom_id': classroomId});
    return (raw as List).whereType<Map>().map((item) => Map<String, dynamic>.from(item)).toList();
  }

  Future<Map<String, dynamic>> createSchedule(Map<String, dynamic> data) async => Map<String, dynamic>.from(await client.post('/schedules', body: data));

  Future<void> deleteSchedule(int id) => client.delete('/schedules/$id');

  Future<List<Map<String, dynamic>>> blocks() async => _records(await client.get('/blocks'));

  Future<Map<String, dynamic>> createBlock(Map<String, dynamic> data) async => Map<String, dynamic>.from(await client.post('/blocks', body: data));

  Future<void> deleteBlock(int id) => client.delete('/blocks/$id');

  Future<Map<String, dynamic>> reports({DateTime? from, DateTime? to}) async {
    return Map<String, dynamic>.from(await client.get('/reports/summary', query: {
      if (from != null) 'from': from.toIso8601String(),
      if (to != null) 'to': to.toIso8601String(),
    }));
  }

  List<Map<String, dynamic>> _records(dynamic raw) {
    final list = raw is Map ? raw['data'] : raw;
    return (list as List? ?? []).whereType<Map>().map((item) => Map<String, dynamic>.from(item)).toList();
  }
}

