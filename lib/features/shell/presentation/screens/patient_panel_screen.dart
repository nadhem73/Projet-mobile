import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:medilink/core/di/injection.dart';
import 'package:medilink/core/modules/module_registry.dart';
import 'package:medilink/core/session/session_service.dart';
import 'package:medilink/core/theme/app_colors.dart';
import 'package:medilink/core/theme/app_dimens.dart';
import 'package:medilink/core/widgets/widgets.dart';
import 'package:medilink/features/appointment/appointment_module.dart';
import 'package:medilink/features/appointment/presentation/screens/rendez_vous_screen.dart';
import 'package:medilink/features/user/data/models/medical_record.dart';
import 'package:medilink/features/user/data/repositories/medical_record_repository.dart';
import 'package:medilink/features/user/presentation/screens/medical_record/medical_record_screen.dart';
import 'package:medilink/features/user/presentation/screens/profile/profile_screen.dart';
import 'package:medilink/features/user/presentation/widgets/user_avatar.dart';
import 'package:medilink/features/user/user_module.dart';

/// Panel du patient : barre de navigation Accueil / Rendez-vous / Dossier / Profil.
class PatientPanelScreen extends StatefulWidget {
  const PatientPanelScreen({super.key});

  @override
  State<PatientPanelScreen> createState() => _PatientPanelScreenState();
}

class _PatientPanelScreenState extends State<PatientPanelScreen> {
  int _index = 0;

  /// Routes déjà accessibles par un onglet : pas de doublon dans la grille de services.
  static const _tabRoutes = {AppointmentRoutes.list, UserRoutes.medicalRecord};

  void _open(int index) => setState(() => _index = index);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          _PatientHomeTab(onOpenTab: _open, hiddenRoutes: _tabRoutes),
          const MLRendezVousScreen(),
          const MedicalRecordScreen(),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _open,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Accueil',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month_rounded),
            label: 'Rendez-vous',
          ),
          NavigationDestination(
            icon: Icon(Icons.folder_shared_outlined),
            selectedIcon: Icon(Icons.folder_shared_rounded),
            label: 'Dossier',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}

class _PatientHomeTab extends StatefulWidget {
  const _PatientHomeTab({required this.onOpenTab, required this.hiddenRoutes});

  final ValueChanged<int> onOpenTab;
  final Set<String> hiddenRoutes;

  @override
  State<_PatientHomeTab> createState() => _PatientHomeTabState();
}

class _PatientHomeTabState extends State<_PatientHomeTab> {
  final _session = getIt<SessionService>();
  MedicalRecord? _record;

  @override
  void initState() {
    super.initState();
    _loadRecord();
  }

  Future<void> _loadRecord() async {
    final patientId = _session.currentUser?.patientId;
    if (patientId == null) return;
    final record = await getIt<MedicalRecordRepository>().forPatient(patientId);
    if (mounted) setState(() => _record = record);
  }

  String get _greeting {
    final hour = DateTime.now().hour;
    return hour < 18 ? 'Bonjour,' : 'Bonsoir,';
  }

  @override
  Widget build(BuildContext context) {
    final user = _session.currentUser;
    final shortcuts = getIt<ModuleRegistry>().patientShortcuts.where((s) => !widget.hiddenRoutes.contains(s.route));

    return RefreshIndicator(
      onRefresh: _loadRecord,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: PanelHeader(
              greeting: _greeting,
              title: user?.fullName ?? '',
              subtitle: 'Prenez soin de vous aujourd\'hui',
              initials: user?.initials ?? '',
              avatar:
                  user == null
                      ? null
                      : UserAvatar(userId: user.userId, initials: user.initials, size: 52, onDark: true),
              onAvatarTap: () => widget.onOpenTab(3),
              actions: const [NotificationBell(onDark: true)],
              bottom: _HealthSummary(record: _record, onTap: () => widget.onOpenTab(2)),
            ),
          ),
          const SliverPadding(
            padding: EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, 0),
            sliver: SliverToBoxAdapter(child: SectionHeader(title: 'Services')),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 200,
                mainAxisExtent: ShortcutTile.compactHeight,
                crossAxisSpacing: AppSpacing.md,
                mainAxisSpacing: AppSpacing.md,
              ),
              delegate: SliverChildListDelegate([
                for (final s in shortcuts)
                  ShortcutTile(icon: s.icon, label: s.label, color: s.color, onTap: () => context.push(s.route)),
              ]),
            ),
          ),
          const SliverPadding(
            padding: EdgeInsets.all(AppSpacing.lg),
            sliver: SliverToBoxAdapter(child: _EmergencyCard()),
          ),
        ],
      ),
    );
  }
}

/// Résumé santé affiché dans l'en-tête (groupe sanguin, IMC, allergies).
class _HealthSummary extends StatelessWidget {
  const _HealthSummary({required this.record, required this.onTap});

  final MedicalRecord? record;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final r = record;
    Widget item(String label, String value) => Expanded(
      child: Column(
        children: [
          Text(value, style: theme.textTheme.titleMedium?.copyWith(color: Colors.white)),
          Text(label, style: theme.textTheme.labelSmall?.copyWith(color: Colors.white70)),
        ],
      ),
    );

    return Material(
      color: Colors.white.withValues(alpha: 0.14),
      borderRadius: AppRadius.card,
      child: InkWell(
        borderRadius: AppRadius.card,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md, horizontal: AppSpacing.sm),
          child: Row(
            children: [
              item('Groupe sanguin', r?.bloodGroup ?? '—'),
              item('IMC', r?.bmi?.toStringAsFixed(1) ?? '—'),
              item('Allergies', r == null ? '—' : '${r.allergyList.length}'),
              const Icon(Icons.chevron_right_rounded, color: Colors.white70),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmergencyCard extends StatelessWidget {
  const _EmergencyCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return MediCard(
      color: AppColors.error.withValues(alpha: 0.06),
      borderColor: AppColors.error.withValues(alpha: 0.25),
      child: Row(
        children: [
          const Icon(Icons.emergency_rounded, color: AppColors.error),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Numéros d\'urgence', style: theme.textTheme.titleSmall),
                const SizedBox(height: 2),
                Text(
                  'SAMU 190 · Protection civile 198 · Police 197',
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
