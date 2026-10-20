import 'package:flutter/material.dart';
import 'package:medilink/core/di/injection.dart';
import 'package:medilink/core/session/session_service.dart';
import 'package:medilink/core/theme/app_colors.dart';
import 'package:medilink/core/theme/app_dimens.dart';
import 'package:medilink/core/widgets/widgets.dart';
import 'package:medilink/features/user/data/models/medical_file_models.dart';
import 'package:medilink/features/user/data/models/medical_record.dart';
import 'package:medilink/features/user/data/repositories/medical_record_repository.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// Carte d'urgence : informations vitales lisibles d'un coup d'œil par les
/// secours, et QR code qui les contient (lisible par n'importe quel téléphone,
/// sans connexion).
class EmergencyCardScreen extends StatefulWidget {
  const EmergencyCardScreen({super.key});

  @override
  State<EmergencyCardScreen> createState() => _EmergencyCardScreenState();
}

class _EmergencyCardScreenState extends State<EmergencyCardScreen> {
  late final Future<(PatientIdentity, MedicalRecord)?> _data = _load();

  Future<(PatientIdentity, MedicalRecord)?> _load() async {
    final patientId = getIt<SessionService>().currentUser?.patientId;
    if (patientId == null) return null;
    final repository = getIt<MedicalRecordRepository>();
    return (await repository.identity(patientId), await repository.forPatient(patientId));
  }

  /// Texte encodé dans le QR code.
  static String qrText(PatientIdentity p, MedicalRecord r) => [
    'MEDILINK - CARTE D\'URGENCE',
    'Nom : ${p.fullName}${p.age == null ? '' : ' (${p.age} ans)'}',
    if (r.genderLabel != null) 'Sexe : ${r.genderLabel}',
    'Groupe sanguin : ${r.bloodGroup ?? 'inconnu'}',
    'Allergies : ${r.allergyList.isEmpty ? 'aucune connue' : r.allergyList.join(', ')}',
    if (r.chronicDiseaseList.isNotEmpty) 'Maladies chroniques : ${r.chronicDiseaseList.join(', ')}',
    if (r.currentTreatment != null) 'Traitement : ${r.currentTreatment}',
    if (r.emergencyContactName != null || r.emergencyContactPhone != null)
      'Contact : ${[r.emergencyContactName, r.emergencyContactPhone].whereType<String>().join(' ')}',
  ].join('\n');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Carte d\'urgence')),
      body: FutureBuilder(
        future: _data,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) return const LoadingView();
          final data = snapshot.data;
          if (snapshot.hasError || data == null) {
            return const EmptyState(
              icon: Icons.qr_code_2_rounded,
              title: 'Carte indisponible',
              message: 'La carte d\'urgence est disponible depuis un compte patient.',
            );
          }
          final (patient, record) = data;
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              _Card(patient: patient, record: record),
              const SizedBox(height: AppSpacing.xl),
              Center(
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: AppRadius.card,
                    border: Border.all(color: AppColors.border),
                  ),
                  child: QrImageView(
                    data: qrText(patient, record),
                    size: 220,
                    backgroundColor: Colors.white,
                    semanticsLabel: 'QR code de la carte d\'urgence',
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Les secours peuvent scanner ce code avec n\'importe quel téléphone, même sans connexion. '
                'Astuce : faites une capture d\'écran et mettez-la en fond d\'écran de verrouillage.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.patient, required this.record});

  final PatientIdentity patient;
  final MedicalRecord record;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget line(IconData icon, String label, String value) => Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.error),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: '$label : ', style: const TextStyle(fontWeight: FontWeight.w600)),
                  TextSpan(text: value),
                ],
              ),
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.error.withValues(alpha: 0.4), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: AppColors.error,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
            child: Row(
              children: [
                const Icon(Icons.emergency_rounded, color: Colors.white),
                const SizedBox(width: AppSpacing.sm),
                Text('URGENCE MÉDICALE', style: theme.textTheme.titleSmall?.copyWith(color: Colors.white)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(patient.fullName, style: theme.textTheme.titleLarge),
                          Text(
                            [
                              record.genderLabel,
                              if (patient.age != null) '${patient.age} ans',
                            ].whereType<String>().join(' · '),
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        borderRadius: AppRadius.card,
                      ),
                      child: Column(
                        children: [
                          Text(
                            record.bloodGroup ?? '?',
                            style: theme.textTheme.headlineSmall?.copyWith(color: AppColors.error),
                          ),
                          Text('Groupe', style: theme.textTheme.labelSmall),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                line(
                  Icons.warning_amber_rounded,
                  'Allergies',
                  record.allergyList.isEmpty ? 'aucune connue' : record.allergyList.join(', '),
                ),
                if (record.chronicDiseaseList.isNotEmpty)
                  line(Icons.monitor_heart_outlined, 'Maladies chroniques', record.chronicDiseaseList.join(', ')),
                if (record.currentTreatment != null)
                  line(Icons.medication_outlined, 'Traitement', record.currentTreatment!),
                line(
                  Icons.contact_phone_outlined,
                  'Contact',
                  [record.emergencyContactName, record.emergencyContactPhone].whereType<String>().join(' — ').isEmpty
                      ? 'non renseigné'
                      : [record.emergencyContactName, record.emergencyContactPhone].whereType<String>().join(' — '),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
