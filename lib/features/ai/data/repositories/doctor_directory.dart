import 'package:medilink/core/database/app_database.dart';
import 'package:medilink/features/ai/data/models/doctor_option.dart';

/// Médecins actifs pouvant recevoir un bilan (équivalent local de `GET /auth/doctors`).
///
/// Lecture seule des tables du module User : aucun repository partagé
/// n'expose encore la liste des médecins. À remplacer par la méthode du
/// module User dès qu'elle existe (CONTRIBUTING, règle 6).
class DoctorDirectory {
  DoctorDirectory(this._database);

  final AppDatabase _database;

  Future<List<DoctorOption>> all() async {
    final rows = await _database.db.rawQuery('''
      SELECT d.doctor_id, d.specialty, d.license_number,
             u.id AS user_id, u.nom, u.prenom, u.email, u.phone, p.city
      FROM doctors d
      JOIN users u ON u.id = d.user_id
      LEFT JOIN doctor_profiles p ON p.doctor_id = d.doctor_id
      WHERE u.status = 'ACTIVE'
      ORDER BY u.nom COLLATE NOCASE, u.prenom COLLATE NOCASE
    ''');
    return rows.map(DoctorOption.fromMap).toList();
  }
}
