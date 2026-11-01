import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:medilink/core/di/injection.dart';
import 'package:medilink/core/error/app_exception.dart';
import 'package:medilink/core/session/session_service.dart';
import 'package:medilink/core/theme/app_colors.dart';
import 'package:medilink/core/theme/app_dimens.dart';
import 'package:medilink/core/widgets/widgets.dart';
import 'package:medilink/features/user/data/models/medical_file_models.dart';
import 'package:medilink/features/user/data/repositories/medical_access_repository.dart';
import 'package:medilink/features/user/presentation/widgets/medical_file_widgets.dart';
import 'package:medilink/features/user/presentation/widgets/medical_record_view.dart';
import 'package:medilink/features/user/user_module.dart';

/// Espace médecin : patients dont il peut consulter le dossier
/// (ceux qui ont un rendez-vous avec lui).
class DoctorPatientsRecordsScreen extends StatefulWidget {
  const DoctorPatientsRecordsScreen({super.key});

  @override
  State<DoctorPatientsRecordsScreen> createState() => _DoctorPatientsRecordsScreenState();
}

class _DoctorPatientsRecordsScreenState extends State<DoctorPatientsRecordsScreen> {
  final _repository = getIt<MedicalAccessRepository>();
  final int? _doctorId = getIt<SessionService>().currentUser?.doctorId;
  Timer? _debounce;
  String _query = '';
  late Future<List<PatientIdentity>> _patients = _fetch();

  Future<List<PatientIdentity>> _fetch() =>
      _doctorId == null ? Future.value(const []) : _repository.patientsOf(_doctorId, query: _query);

  void _onSearch(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      setState(() {
        _query = value;
        _patients = _fetch();
      });
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Dossiers de mes patients')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.md),
            child: TextField(
              onChanged: _onSearch,
              decoration: const InputDecoration(
                hintText: 'Rechercher un patient',
                prefixIcon: Icon(Icons.search_rounded),
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder(
              future: _patients,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) return const LoadingView();
                final patients = snapshot.data ?? const [];
                if (patients.isEmpty) {
                  return EmptyState(
                    icon: Icons.folder_shared_outlined,
                    title: _query.isEmpty ? 'Aucun patient' : 'Aucun résultat',
                    message: 'Vous accédez au dossier des patients qui ont pris rendez-vous avec vous.',
                  );
                }
                final date = DateFormat('d MMM yyyy', 'fr');
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
                  itemCount: patients.length,
                  separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, i) {
                    final p = patients[i];
                    return MediCard(
                      onTap: () => context.push(UserRoutes.doctorPatientRecord(p.patientId)),
                      child: Row(
                        children: [
                          MediAvatar(initials: p.initials, size: 48),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(p.fullName, style: theme.textTheme.titleMedium),
                                Text(
                                  [
                                    if (p.age != null) '${p.age} ans',
                                    if (p.lastAppointment != null) 'RDV : ${date.format(p.lastAppointment!)}',
                                  ].join(' · '),
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Dossier d'un patient vu par le médecin (lecture seule, consultation tracée).
class DoctorPatientRecordScreen extends StatefulWidget {
  const DoctorPatientRecordScreen({super.key, required this.patientId});

  final int patientId;

  @override
  State<DoctorPatientRecordScreen> createState() => _DoctorPatientRecordScreenState();
}

class _DoctorPatientRecordScreenState extends State<DoctorPatientRecordScreen> {
  late final Future<PatientMedicalFile> _file = getIt<MedicalAccessRepository>().openAsDoctor(
    doctorId: getIt<SessionService>().requireUser.doctorId!,
    patientId: widget.patientId,
  );

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _file,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return Scaffold(appBar: AppBar(title: const Text('Dossier médical')), body: const LoadingView());
        }
        final file = snapshot.data;
        if (file == null) {
          final error = snapshot.error;
          return Scaffold(
            appBar: AppBar(title: const Text('Dossier médical')),
            body: EmptyState(
              icon: Icons.lock_outline_rounded,
              title: 'Accès refusé',
              message: error is AppException ? error.message : 'Dossier indisponible',
              color: AppColors.error,
            ),
          );
        }
        final theme = Theme.of(context);
        return DefaultTabController(
          length: 3,
          child: Scaffold(
            appBar: AppBar(
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [Text(file.patient.fullName), Text('Dossier médical', style: theme.textTheme.bodySmall)],
              ),
              bottom: const TabBar(tabs: [Tab(text: 'Résumé'), Tab(text: 'Vaccins'), Tab(text: 'Documents')]),
            ),
            body: TabBarView(
              children: [
                ListView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: AppColors.info.withValues(alpha: 0.08),
                        borderRadius: AppRadius.card,
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.shield_outlined, color: AppColors.info),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Text(
                              'Consultation enregistrée et visible par le patient (secret médical).',
                              style: theme.textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    ),
                    MedicalRecordView(record: file.record, age: file.patient.age),
                  ],
                ),
                ListView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  children: [VaccinationList(vaccinations: file.vaccinations)],
                ),
                ListView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  children: [DocumentGrid(documents: file.documents)],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
