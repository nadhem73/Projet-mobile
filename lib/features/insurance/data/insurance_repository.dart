import 'package:medilink/core/database/app_database.dart';
import 'package:medilink/core/error/app_exception.dart';
import 'package:medilink/core/session/session_service.dart';
import 'package:medilink/core/session/user_role.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:medilink/core/notifications/notification_service.dart';
import 'package:medilink/features/insurance/data/insurance_dossier.dart';
import 'package:medilink/features/user/data/models/medical_file_models.dart';
import 'package:medilink/features/user/data/repositories/medical_record_repository.dart';

/// Local insurance data. Every operation derives its scope from the session.
class InsuranceRepository {
  InsuranceRepository(this._database, this._session, [this._notifications]);

  final AppDatabase _database;
  final SessionService _session;
  final NotificationService? _notifications;
  final changes = ValueNotifier<int>(0);

  void _changed() {
    changes.value++;
    _notifications?.refreshAfterTransaction();
  }

  bool get isPatient => _session.currentUser?.isPatient ?? false;
  UserRole get role => _session.requireUser.role;

  int get _patientId {
    final user = _session.requireUser;
    if (!user.isPatient || user.patientId == null) {
      throw const AppException('Accès réservé aux patients.');
    }
    return user.patientId!;
  }

  Future<String> _insurerCompany() async {
    final user = _session.requireUser;
    if (!user.isInsurer || user.insurerId == null) {
      throw const AppException('Accès réservé aux assureurs.');
    }
    final rows = await _database.db.rawQuery(
      "SELECT i.company FROM insurers i JOIN users u ON u.id = i.user_id "
      "WHERE i.insurer_id = ? AND u.id = ? AND u.status = 'ACTIVE'",
      [user.insurerId, user.userId],
    );
    if (rows.isEmpty) throw const AppException('Compte assureur indisponible.');
    return rows.first['company'] as String;
  }

  Future<List<Map<String, Object?>>> patientContracts() => _database.db.query(
    'insurance_contracts',
    where: 'patient_id = ?',
    whereArgs: [_patientId],
    orderBy: 'contract_id DESC',
  );

  Future<int> addContract({
    required String company,
    required String policyNumber,
    required double coverageRate,
  }) async {
    final patientId = _patientId;
    if (company.trim().isEmpty ||
        policyNumber.trim().isEmpty ||
        !coverageRate.isFinite ||
        coverageRate < 0 ||
        coverageRate > 1) {
      throw const AppException(
        'Vérifiez l’organisme, le numéro et le taux de couverture.',
      );
    }
    final id = await _database.db.transaction((txn) async {
      final duplicate = await txn.query(
        'insurance_contracts',
        columns: ['contract_id'],
        where:
            'patient_id = ? AND trim(company) = ? COLLATE NOCASE AND trim(policy_number) = ? COLLATE NOCASE',
        whereArgs: [patientId, company.trim(), policyNumber.trim()],
      );
      if (duplicate.isNotEmpty) {
        throw const AppException('Ce contrat est déjà enregistré.');
      }
      return txn.insert('insurance_contracts', {
        'patient_id': patientId,
        'company': company.trim(),
        'policy_number': policyNumber.trim(),
        'coverage_rate': coverageRate,
      });
    });
    _changed();
    return id;
  }

  Future<List<Map<String, Object?>>> patientClaims() => _database.db.rawQuery(
    'SELECT c.*, t.company, t.policy_number, t.coverage_rate FROM insurance_claims c '
    'JOIN insurance_contracts t ON t.contract_id = c.contract_id WHERE t.patient_id = ? '
    'ORDER BY c.claim_id DESC',
    [_patientId],
  );

  Future<int> submitClaim({
    required int contractId,
    required double amount,
    DateTime? careDate,
    List<InsuranceAttachment> attachments = const [],
    int? consultationId,
    int? prescriptionId,
  }) async {
    final patientId = _patientId;
    final actor = _session.requireUser.fullName;
    if (!amount.isFinite || amount <= 0 || amount > 10000000) {
      throw const AppException('Saisissez un montant valide.');
    }
    _validateAttachments(attachments);
    if (careDate != null &&
        (careDate.year < 1900 || careDate.isAfter(DateTime.now()))) {
      throw const AppException('Vérifiez la date des soins.');
    }
    final id = await _database.db.transaction((txn) async {
      final contracts = await txn.rawQuery(
        'SELECT * FROM insurance_contracts WHERE contract_id = ? AND patient_id = ?',
        [contractId, patientId],
      );
      if (contracts.isEmpty ||
          !contractIsUsable(contracts.first) ||
          (careDate != null && !contractIsUsable(contracts.first, careDate))) {
        throw const AppException(
          'Ce contrat n’est pas disponible pour une demande.',
        );
      }
      await _validateLink(
        txn,
        'consultations',
        'consultation_id',
        consultationId,
        patientId,
      );
      await _validateLink(
        txn,
        'prescriptions',
        'prescription_id',
        prescriptionId,
        patientId,
      );
      if (prescriptionId != null && consultationId != null) {
        final prescription =
            (await txn.query(
              'prescriptions',
              where: 'prescription_id = ?',
              whereArgs: [prescriptionId],
            )).single;
        if (prescription['consultation_id'] != consultationId) {
          throw const AppException(
            'Cette ordonnance ne correspond pas à la consultation.',
          );
        }
      }
      final dossier = InsuranceDossier(
        careDate: careDate?.toIso8601String().substring(0, 10),
        attachments: List.of(attachments),
      )..record('SUBMITTED', actor);
      final id = await txn.insert('insurance_claims', {
        'contract_id': contractId,
        'amount': amount,
        'consultation_id': consultationId,
        'prescription_id': prescriptionId,
        'document_path': dossier.encode(),
      });
      await _notifyInsurers(
        txn,
        contracts.first['company'] as String,
        id,
        'Nouvelle demande',
        'Le dossier #$id est à examiner.',
      );
      return id;
    });
    _changed();
    return id;
  }

  Future<List<Map<String, Object?>>> insurerContracts() async {
    final company = await _insurerCompany();
    return _database.db.rawQuery(
      'SELECT t.*, u.prenom, u.nom FROM insurance_contracts t JOIN patients p ON p.patient_id = t.patient_id '
      'JOIN users u ON u.id = p.user_id WHERE trim(t.company) = ? COLLATE NOCASE ORDER BY t.contract_id DESC',
      [company.trim()],
    );
  }

  Future<List<Map<String, Object?>>> insurerClaims() async {
    final company = await _insurerCompany();
    return _database.db.rawQuery(
      'SELECT c.*, t.company, t.policy_number, t.coverage_rate, u.prenom, u.nom '
      'FROM insurance_claims c JOIN insurance_contracts t ON t.contract_id = c.contract_id '
      'JOIN patients p ON p.patient_id = t.patient_id JOIN users u ON u.id = p.user_id '
      'WHERE trim(t.company) = ? COLLATE NOCASE ORDER BY c.claim_id DESC',
      [company.trim()],
    );
  }

  /// Decisions are recorded locally; no external reimbursement is executed.
  Future<void> changeClaimStatus(
    int claimId,
    String next, {
    String? reason,
    double? approvedAmount,
  }) async {
    final company = await _insurerCompany();
    final actor = _session.requireUser.fullName;
    if (!['APPROVED', 'REJECTED', 'PAID'].contains(next)) {
      throw const AppException('Décision invalide.');
    }
    await _database.db.transaction((txn) async {
      final claims = await txn.rawQuery(
        'SELECT c.*, t.coverage_rate, p.user_id FROM insurance_claims c JOIN insurance_contracts t ON t.contract_id = c.contract_id '
        'JOIN patients p ON p.patient_id = t.patient_id '
        'WHERE c.claim_id = ? AND trim(t.company) = ? COLLATE NOCASE',
        [claimId, company.trim()],
      );
      if (claims.isEmpty) throw const AppException('Demande introuvable.');
      final claim = claims.first;
      final dossier = InsuranceDossier.decode(claim['document_path']);
      final expected = next == 'PAID' ? 'APPROVED' : 'SUBMITTED';
      if (claim['status'] != expected) {
        throw const AppException('Cette demande a déjà été traitée.');
      }
      final estimate = insuranceEstimate(
        claim['amount'] as num,
        claim['coverage_rate'] as num,
      );
      final accepted = approvedAmount ?? estimate;
      if (next == 'APPROVED' &&
          (!accepted.isFinite ||
              accepted < 0 ||
              accepted > (claim['amount'] as num))) {
        throw const AppException(
          'Le montant retenu doit être compris entre 0 et les frais déclarés.',
        );
      }
      if (next == 'APPROVED' && dossier.requestedDocuments != null) {
        throw const AppException(
          'Attendez le complément demandé avant de décider.',
        );
      }
      if ((next == 'REJECTED' ||
              (next == 'APPROVED' && accepted != estimate)) &&
          (reason == null || reason.trim().isEmpty)) {
        throw const AppException(
          'Indiquez un motif pour expliquer cette décision.',
        );
      }
      if ((reason?.length ?? 0) > 1000) {
        throw const AppException(
          'Le motif doit rester inférieur à 1 000 caractères.',
        );
      }
      dossier.requestedDocuments = null;
      dossier.record(
        next,
        actor,
        note: reason,
        amount: next == 'APPROVED' ? insuranceEstimate(accepted, 1) : null,
      );
      await txn.update(
        'insurance_claims',
        {
          'status': next,
          'document_path': dossier.encode(),
          if (next == 'APPROVED')
            'reimbursed_amount': insuranceEstimate(accepted, 1),
          if (next == 'REJECTED') 'reimbursed_amount': null,
        },
        where: 'claim_id = ? AND status = ?',
        whereArgs: [claimId, expected],
      );
      final label =
          {
            'APPROVED': 'approuvée',
            'REJECTED': 'refusée',
            'PAID': 'marquée payée',
          }[next];
      await _notify(
        txn,
        claim['user_id'] as int,
        claimId,
        'Demande #$claimId $label',
        next == 'PAID'
            ? 'Paiement enregistré par votre organisme. Aucun virement n’est exécuté par MediLink.'
            : reason ?? 'Consultez le détail de la décision.',
      );
    });
    _changed();
  }

  Future<Map<String, Object?>> claim(int id) async {
    final user = _session.requireUser;
    final String scope;
    final Object argument;
    if (user.isPatient) {
      scope = 't.patient_id = ?';
      argument = _patientId;
    } else {
      scope = 'trim(t.company) = ? COLLATE NOCASE';
      argument = (await _insurerCompany()).trim();
    }
    final rows = await _database.db.rawQuery(
      'SELECT c.*, t.company, t.policy_number, t.coverage_rate, u.prenom, u.nom '
      'FROM insurance_claims c JOIN insurance_contracts t ON t.contract_id = c.contract_id '
      'JOIN patients p ON p.patient_id = t.patient_id JOIN users u ON u.id = p.user_id '
      'WHERE c.claim_id = ? AND $scope',
      [id, argument],
    );
    if (rows.isEmpty) {
      throw const AppException('Demande introuvable ou accès non autorisé.');
    }
    return rows.single;
  }

  Future<void> requestDocuments(int claimId, String message) async {
    final company = await _insurerCompany();
    final actor = _session.requireUser.fullName;
    if (message.trim().isEmpty || message.length > 1000) {
      throw const AppException(
        'Précisez les pièces attendues (1 000 caractères maximum).',
      );
    }
    await _database.db.transaction((txn) async {
      final rows = await txn.rawQuery(
        'SELECT c.*, p.user_id FROM insurance_claims c JOIN insurance_contracts t ON t.contract_id = c.contract_id '
        'JOIN patients p ON p.patient_id = t.patient_id WHERE c.claim_id = ? AND trim(t.company) = ? COLLATE NOCASE',
        [claimId, company.trim()],
      );
      if (rows.isEmpty || rows.single['status'] != 'SUBMITTED') {
        throw const AppException('Cette demande ne peut plus être complétée.');
      }
      final dossier = InsuranceDossier.decode(rows.single['document_path']);
      if (dossier.requestedDocuments != null) {
        throw const AppException('Un complément est déjà attendu.');
      }
      dossier.requestedDocuments = message.trim();
      dossier.record('DOCUMENTS_REQUESTED', actor, note: message);
      await txn.update(
        'insurance_claims',
        {'document_path': dossier.encode()},
        where: 'claim_id = ?',
        whereArgs: [claimId],
      );
      await _notify(
        txn,
        rows.single['user_id'] as int,
        claimId,
        'Pièces attendues · dossier #$claimId',
        message.trim(),
      );
    });
    _changed();
  }

  Future<void> complementClaim(
    int claimId, {
    required List<InsuranceAttachment> attachments,
    required String note,
  }) async {
    final patientId = _patientId;
    final actor = _session.requireUser.fullName;
    if (note.trim().isEmpty || note.length > 1000) {
      throw const AppException(
        'Expliquez votre complément (1 000 caractères maximum).',
      );
    }
    await _database.db.transaction((txn) async {
      final rows = await txn.rawQuery(
        'SELECT c.*, t.company FROM insurance_claims c JOIN insurance_contracts t ON t.contract_id = c.contract_id WHERE c.claim_id = ? AND t.patient_id = ?',
        [claimId, patientId],
      );
      if (rows.isEmpty || rows.single['status'] != 'SUBMITTED') {
        throw const AppException('Cette demande ne peut plus être modifiée.');
      }
      final dossier = InsuranceDossier.decode(rows.single['document_path']);
      _validateAttachments([...dossier.attachments, ...attachments]);
      dossier.attachments.addAll(attachments);
      dossier.requestedDocuments = null;
      dossier.record('COMPLEMENT', actor, note: note);
      await txn.update(
        'insurance_claims',
        {'document_path': dossier.encode()},
        where: 'claim_id = ?',
        whereArgs: [claimId],
      );
      await _notifyInsurers(
        txn,
        rows.single['company'] as String,
        claimId,
        'Dossier #$claimId complété',
        'Un complément est disponible pour examen.',
      );
    });
    _changed();
  }

  Future<List<MedicalDocument>> patientDocuments() =>
      MedicalRecordRepository(_database).documents(_patientId);

  /// Only identifiers/dates are exposed; the insurer never gets clinical notes.
  Future<List<Map<String, Object?>>> patientCareLinks() async {
    final id = _patientId;
    return _database.db.rawQuery(
      "SELECT consultation_id AS id, 'consultation' AS kind, start_time AS date FROM consultations WHERE patient_id = ? "
      "UNION ALL SELECT prescription_id AS id, 'prescription' AS kind, created_at AS date FROM prescriptions WHERE patient_id = ? ORDER BY date DESC",
      [id, id],
    );
  }

  static Future<void> _validateLink(
    Transaction txn,
    String table,
    String column,
    int? id,
    int patientId,
  ) async {
    if (id == null) return;
    final rows = await txn.query(
      table,
      columns: [column],
      where: '$column = ? AND patient_id = ?',
      whereArgs: [id, patientId],
    );
    if (rows.isEmpty) {
      throw const AppException('Le soin associé ne vous appartient pas.');
    }
  }

  static void _validateAttachments(List<InsuranceAttachment> attachments) {
    if (attachments.length > 5 ||
        attachments.fold<int>(0, (n, a) => n + a.bytes.length) >
            6 * 1024 * 1024) {
      throw const AppException(
        'Limite du dossier : 5 images et 6 Mo au total.',
      );
    }
    for (final a in attachments) {
      a.validate();
    }
  }

  static Future<void> _notify(
    Transaction txn,
    int userId,
    int claimId,
    String title,
    String body,
  ) async {
    await txn.insert('notifications', {
      'user_id': userId,
      'type': NotificationTypes.insurance,
      'title': title,
      'body': body,
      'payload': jsonEncode({'claimId': claimId}),
    });
  }

  static Future<void> _notifyInsurers(
    Transaction txn,
    String company,
    int claimId,
    String title,
    String body,
  ) async {
    final users = await txn.rawQuery(
      "SELECT u.id FROM users u JOIN insurers i ON i.user_id = u.id WHERE u.status = 'ACTIVE' AND trim(i.company) = ? COLLATE NOCASE",
      [company.trim()],
    );
    for (final user in users) {
      await _notify(txn, user['id'] as int, claimId, title, body);
    }
  }
}
