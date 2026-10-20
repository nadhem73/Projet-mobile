import 'package:flutter/foundation.dart';
import 'package:medilink/core/config/app_config.dart';
import 'package:medilink/core/database/database_seeder.dart';
import 'package:medilink/core/database/schema/appointment_schema.dart';
import 'package:medilink/core/database/schema/doctor_schema.dart';
import 'package:medilink/core/database/schema/insurance_schema.dart';
import 'package:medilink/core/database/schema/pharmacy_schema.dart';
import 'package:medilink/core/database/schema/shared_schema.dart';
import 'package:medilink/core/database/schema/user_schema.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Base SQLite principale de l'application (cahier des charges §9.1).
///
/// Une seule instance, enregistrée dans get_it. Les repositories de chaque
/// module récupèrent la connexion via `getIt<AppDatabase>().db`.
///
/// ## Modifier le schéma
/// 1. Modifier le fichier `schema/<module>_schema.dart` de votre module.
/// 2. Incrémenter [version] ci-dessous.
/// 3. Relancer l'app : en phase de développement la base est recréée
///    (les comptes de démo sont réinsérés par [DatabaseSeeder]).
class AppDatabase {
  AppDatabase._(this.db);

  /// ⚠️ Incrémenter à chaque modification d'un fichier de schéma.
  static const int version = 3;

  /// Ordre important : les tables référencées doivent être créées avant.
  static const List<List<String>> _schemas = [
    userSchema,
    appointmentSchema,
    doctorSchema,
    insuranceSchema,
    pharmacySchema,
    sharedSchema,
  ];

  final Database db;

  static Future<AppDatabase> open({DatabaseFactory? factory, String? path, bool seed = true}) async {
    final dbFactory = factory ?? databaseFactory;
    final dbPath = path ?? p.join(await dbFactory.getDatabasesPath(), AppConfig.databaseName);

    final database = await dbFactory.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: version,
        onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
        onCreate: (db, _) => _create(db, seed: seed),
        onUpgrade: (db, oldVersion, newVersion) async {
          debugPrint('[AppDatabase] schéma v$oldVersion → v$newVersion : recréation de la base');
          await dropAll(db);
          await _create(db, seed: seed);
        },
      ),
    );
    return AppDatabase._(database);
  }

  static Future<void> _create(Database db, {required bool seed}) async {
    final batch = db.batch();
    for (final schema in _schemas) {
      for (final statement in schema) {
        batch.execute(statement);
      }
    }
    await batch.commit(noResult: true);
    if (seed) await DatabaseSeeder(db).seed();
  }

  /// Supprime toutes les tables de l'application.
  ///
  /// sqflite exécute `onUpgrade` dans une transaction, où `PRAGMA foreign_keys`
  /// est sans effet : les tables sont donc supprimées dans l'ordre inverse de
  /// leur création (tables dépendantes d'abord) pour respecter les clés étrangères.
  @visibleForTesting
  static Future<void> dropAll(DatabaseExecutor db) async {
    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type = 'table' AND name NOT LIKE 'sqlite_%' "
      "AND name <> 'android_metadata' ORDER BY rowid DESC",
    );
    for (final row in tables) {
      await db.execute('DROP TABLE IF EXISTS "${row['name']}"');
    }
  }

  Future<void> close() => db.close();
}
