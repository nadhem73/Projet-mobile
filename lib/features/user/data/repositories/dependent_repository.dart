import 'package:medilink/core/database/app_database.dart';
import 'package:medilink/core/database/schema/user_schema.dart';
import 'package:medilink/core/error/app_exception.dart';
import 'package:medilink/features/user/data/models/dependent.dart';

/// Proches gérés par un patient.
///
/// Réutilisable par le module Rendez-vous : `getIt<DependentRepository>().forPatient(patientId)`.
class DependentRepository {
  DependentRepository(this._database);

  final AppDatabase _database;

  /// Nombre maximum de proches par patient.
  static const int maxDependents = 10;

  Future<List<Dependent>> forPatient(int patientId) async {
    final rows = await _database.db.query(
      UserTables.dependents,
      where: 'patient_id = ?',
      whereArgs: [patientId],
      orderBy: 'prenom, nom',
    );
    return rows.map(Dependent.fromMap).toList();
  }

  Future<void> save(Dependent dependent) async {
    if (dependent.prenom.trim().isEmpty || dependent.nom.trim().isEmpty) {
      throw const AppException('Le nom et le prénom sont obligatoires');
    }
    if (dependent.dateNaissance?.isAfter(DateTime.now()) ?? false) {
      throw const AppException('La date de naissance ne peut pas être dans le futur');
    }
    if (dependent.id == null) {
      final count = (await forPatient(dependent.patientId)).length;
      if (count >= maxDependents) throw const AppException('Vous ne pouvez pas ajouter plus de 10 proches');
      await _database.db.insert(UserTables.dependents, dependent.toMap());
    } else {
      await _database.db.update(
        UserTables.dependents,
        dependent.toMap(),
        where: 'dependent_id = ? AND patient_id = ?',
        whereArgs: [dependent.id, dependent.patientId],
      );
    }
  }

  Future<void> delete({required int patientId, required int dependentId}) => _database.db.delete(
    UserTables.dependents,
    where: 'dependent_id = ? AND patient_id = ?',
    whereArgs: [dependentId, patientId],
  );
}
