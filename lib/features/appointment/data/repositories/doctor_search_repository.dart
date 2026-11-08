import 'package:medilink/core/database/app_database.dart';
import 'package:medilink/core/database/schema/user_schema.dart';
import 'package:medilink/features/appointment/data/models/doctor_summary.dart';

/// Recherche des médecins pour la prise de rendez-vous.
///
/// Seuls les médecins dont le compte est actif (validé par un administrateur)
/// sont proposés aux patients.
class DoctorSearchRepository {
  DoctorSearchRepository(this._database);

  final AppDatabase _database;

  // Jointure commune : médecin + compte + profil (le profil peut manquer).
  static const _select = '''
    SELECT d.doctor_id, d.specialty, u.nom, u.prenom,
           p.biography, p.fee, p.city, p.address, p.working_hours
    FROM doctors d
    JOIN users u ON u.id = d.user_id
    LEFT JOIN doctor_profiles p ON p.doctor_id = d.doctor_id
  ''';

  /// Médecins actifs, filtrés (tous les filtres sont facultatifs) :
  /// - [query] : nom, prénom ou spécialité (recherche partielle) ;
  /// - [specialty] : spécialité exacte ;
  /// - [city] : ville exacte.
  Future<List<DoctorSummary>> search({String query = '', String? specialty, String? city}) async {
    final q = query.trim();
    final where = <String>['u.status = ?'];
    final args = <Object?>[AccountStatus.active];

    if (q.isNotEmpty) {
      where.add("(u.nom LIKE ? OR u.prenom LIKE ? OR (u.prenom || ' ' || u.nom) LIKE ? OR d.specialty LIKE ?)");
      args.addAll(List.filled(4, '%$q%'));
    }
    if (specialty != null && specialty.isNotEmpty) {
      where.add('d.specialty = ?');
      args.add(specialty);
    }
    if (city != null && city.isNotEmpty) {
      where.add('p.city = ?');
      args.add(city);
    }

    final rows = await _database.db.rawQuery(
      '$_select WHERE ${where.join(' AND ')} ORDER BY u.nom COLLATE NOCASE, u.prenom COLLATE NOCASE',
      args,
    );
    return rows.map(DoctorSummary.fromMap).toList();
  }

  /// Fiche d'un médecin actif, ou null s'il n'existe pas / n'est pas actif.
  Future<DoctorSummary?> byId(int doctorId) async {
    final rows = await _database.db.rawQuery('$_select WHERE d.doctor_id = ? AND u.status = ? LIMIT 1', [
      doctorId,
      AccountStatus.active,
    ]);
    return rows.isEmpty ? null : DoctorSummary.fromMap(rows.first);
  }

  /// Spécialités disponibles (pour les filtres), triées par ordre alphabétique.
  Future<List<String>> specialties() async {
    final rows = await _database.db.rawQuery(
      '''
      SELECT DISTINCT d.specialty FROM doctors d
      JOIN users u ON u.id = d.user_id
      WHERE u.status = ?
      ORDER BY d.specialty COLLATE NOCASE
      ''',
      [AccountStatus.active],
    );
    return [for (final r in rows) r['specialty'] as String];
  }

  /// Villes où exerce au moins un médecin actif.
  Future<List<String>> cities() async {
    final rows = await _database.db.rawQuery(
      '''
      SELECT DISTINCT p.city FROM doctor_profiles p
      JOIN doctors d ON d.doctor_id = p.doctor_id
      JOIN users u ON u.id = d.user_id
      WHERE u.status = ? AND p.city IS NOT NULL AND p.city <> ''
      ORDER BY p.city COLLATE NOCASE
      ''',
      [AccountStatus.active],
    );
    return [for (final r in rows) r['city'] as String];
  }
}
