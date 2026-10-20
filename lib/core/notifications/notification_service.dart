import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:medilink/core/database/app_database.dart';
import 'package:medilink/core/database/schema/shared_schema.dart';

/// Types de notifications (colonne `notifications.type`).
abstract final class NotificationTypes {
  static const appointment = 'APPOINTMENT';
  static const prescription = 'PRESCRIPTION';
  static const insurance = 'INSURANCE';
  static const pharmacy = 'PHARMACY';
  static const system = 'SYSTEM';
}

class AppNotification {
  const AppNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    this.body,
    this.payload,
    required this.isRead,
    required this.createdAt,
  });

  final int id;
  final int userId;
  final String type;
  final String title;
  final String? body;
  final Map<String, dynamic>? payload;
  final bool isRead;
  final DateTime createdAt;

  factory AppNotification.fromMap(Map<String, Object?> map) => AppNotification(
    id: map['notification_id'] as int,
    userId: map['user_id'] as int,
    type: map['type'] as String,
    title: map['title'] as String,
    body: map['body'] as String?,
    payload: map['payload'] == null ? null : jsonDecode(map['payload'] as String) as Map<String, dynamic>,
    isRead: (map['is_read'] as int) == 1,
    createdAt: DateTime.parse('${map['created_at']}Z').toLocal(),
  );
}

/// Notifications in-app partagées par tous les modules.
///
/// Exemple (module Médecin, après création d'une ordonnance — §6.4) :
/// ```dart
/// await getIt<NotificationService>().notify(
///   userId: patientUserId,
///   type: NotificationTypes.prescription,
///   title: 'Nouvelle ordonnance disponible',
///   body: 'Dr Benali vous a prescrit 2 médicaments.',
///   payload: {'prescriptionId': id},
/// );
/// ```
class NotificationService extends ChangeNotifier {
  NotificationService(this._database);

  final AppDatabase _database;

  Future<int> notify({
    required int userId,
    required String type,
    required String title,
    String? body,
    Map<String, dynamic>? payload,
  }) async {
    final id = await _database.db.insert(SharedTables.notifications, {
      'user_id': userId,
      'type': type,
      'title': title,
      'body': body,
      'payload': payload == null ? null : jsonEncode(payload),
    });
    notifyListeners();
    return id;
  }

  Future<List<AppNotification>> forUser(int userId) async {
    final rows = await _database.db.query(
      SharedTables.notifications,
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC, notification_id DESC',
    );
    return rows.map(AppNotification.fromMap).toList();
  }

  Future<int> unreadCount(int userId) async {
    final rows = await _database.db.rawQuery(
      'SELECT COUNT(*) AS c FROM ${SharedTables.notifications} WHERE user_id = ? AND is_read = 0',
      [userId],
    );
    return rows.first['c'] as int;
  }

  Future<void> markAllRead(int userId) async {
    await _database.db.update(
      SharedTables.notifications,
      {'is_read': 1},
      where: 'user_id = ? AND is_read = 0',
      whereArgs: [userId],
    );
    notifyListeners();
  }
}
