import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:medilink/core/di/injection.dart';
import 'package:medilink/features/appointment/data/models/appointment.dart';
import 'package:medilink/features/appointment/data/repositories/appointment_repository.dart';
import 'package:medilink/core/theme/app_colors.dart';
import 'package:medilink/core/theme/app_dimens.dart';
import 'package:medilink/core/widgets/widgets.dart';
import 'package:medilink/features/appointment/presentation/controllers/doctor_agenda_controller.dart';
import 'package:medilink/core/session/session_service.dart';
import 'package:medilink/features/doctor/data/models/blocked_slot.dart';
import 'package:medilink/features/doctor/data/repositories/blocked_slot_repository.dart';
import 'package:medilink/features/doctor/presentation/widgets/agenda_timeline.dart';
import 'package:medilink/features/doctor/presentation/widgets/blocked_slot_sheets.dart';
import 'package:medilink/features/doctor/presentation/widgets/agenda_week_calendar.dart';
import 'package:medilink/features/doctor/doctor_module.dart';

/// Onglet « Agenda » du tableau de bord médecin : calendrier de la semaine en haut,
/// frise du jour choisi en dessous (rendez-vous patients + indisponibilités).
///
/// Les rendez-vous viennent du module Rendez-vous ([DoctorAgendaController]) ;
/// les indisponibilités (réunion, pause…) du module Médecin ([BlockedSlotRepository]).
/// Toucher un rendez-vous ouvre son détail ; le bouton « + » bloque un créneau.
class DoctorAgendaTab extends StatefulWidget {
  const DoctorAgendaTab({super.key});

  @override
  State<DoctorAgendaTab> createState() => _DoctorAgendaTabState();
}

class _DoctorAgendaTabState extends State<DoctorAgendaTab> {
  late final DoctorAgendaController _controller = getIt<DoctorAgendaController>()..load();

  /// Rafraîchit la ligne « maintenant » chaque minute.
  late final Timer _clock;

  /// Indisponibilités de la semaine affichée.
  List<BlockedSlot> _blocks = [];
  DateTime? _blocksWeek;

  @override
  void initState() {
    super.initState();
    _clock = Timer.periodic(const Duration(minutes: 1), (_) => setState(() {}));
    _controller.addListener(_syncBlocks);
    _loadBlocks();
  }

  @override
  void dispose() {
    _clock.cancel();
    _controller
      ..removeListener(_syncBlocks)
      ..dispose();
    super.dispose();
  }

  /// Recharge les indisponibilités quand la semaine affichée change.
  void _syncBlocks() {
    if (_blocksWeek != _controller.weekStart) _loadBlocks();
  }

  Future<void> _loadBlocks() async {
    final week = _controller.weekStart;
    _blocksWeek = week;
    final doctorId = getIt<SessionService>().currentUser?.doctorId;
    if (doctorId == null) return;
    final list = await getIt<BlockedSlotRepository>().forDoctorBetween(
      doctorId,
      week,
      DateUtils.addDaysToDate(week, 7),
    );
    if (mounted && _blocksWeek == week) setState(() => _blocks = list);
  }

  List<BlockedSlot> _blocksOn(DateTime day) =>
      _blocks.where((b) => b.overlaps(day, DateUtils.addDaysToDate(day, 1))).toList();

  Future<void> _refresh() => Future.wait([_controller.load(), _loadBlocks()]);

  Future<void> _addBlock() async {
    final saved = await showBlockedSlotForm(context, day: _controller.selectedDay);
    if (saved != true || !mounted) return;
    context.showSuccess('Créneau bloqué : les patients ne peuvent plus le réserver.');
    await _afterBlocksChanged();
  }

  Future<void> _openBlock(BlockedSlot slot) async {
    final deleted = await showBlockedSlotDetail(context, slot);
    if (deleted != true || !mounted) return;
    context.showSuccess('Créneau libéré.');
    await _afterBlocksChanged();
  }

  Future<void> _afterBlocksChanged() async {
    await _loadBlocks();
    // Les écrans de réservation des patients recalculent leurs heures libres.
    getIt<AppointmentRepository>().changes.value++;
  }

  void _goTo(DateTime day) {
    _controller
      ..selectedDay = DateUtils.dateOnly(day)
      ..weekStart = DoctorAgendaController.mondayOf(DateUtils.dateOnly(day))
      ..load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Mon agenda'),
        actions: [
          TextButton.icon(
            onPressed: _controller.goToToday,
            icon: const Icon(Icons.today_rounded),
            label: const Text("Aujourd'hui"),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Bloquer un créneau',
        onPressed: _addBlock,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add_rounded),
      ),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          final c = _controller;
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.xxl),
              children: [
                AgendaWeekCalendar(
                  days: c.weekDays,
                  selectedDay: c.selectedDay,
                  today: c.today,
                  countOn: (day) => c.countOn(day) + _blocksOn(day).length,
                  onSelectDay: c.selectDay,
                  onPreviousWeek: c.previousWeek,
                  onNextWeek: c.nextWeek,
                  onPickDate: _goTo,
                ),
                const SizedBox(height: AppSpacing.xl),
                _DayTitle(
                  day: c.selectedDay,
                  count: c.dayAppointments.length,
                  blocked: _blocksOn(c.selectedDay).length,
                ),
                const SizedBox(height: AppSpacing.lg),
                ..._day(c),
              ],
            ),
          );
        },
      ),
    );
  }

  List<Widget> _day(DoctorAgendaController c) {
    if (c.isLoading && c.weekAppointments.isEmpty) {
      return const [Padding(padding: EdgeInsets.only(top: AppSpacing.xxl), child: LoadingView())];
    }
    if (c.error != null) return [EmptyState.error(c.error!, onRetry: c.load)];
    final items = c.dayAppointments;
    final blocks = _blocksOn(c.selectedDay);
    if (items.isEmpty && blocks.isEmpty) {
      return const [
        EmptyState(
          icon: Icons.event_available_rounded,
          title: 'Journée libre',
          message: 'Aucun patient n\'a réservé ce jour-là. Touchez + pour bloquer un créneau.',
        ),
      ];
    }
    return [
      AgendaTimeline(
        appointments: items,
        blocks: blocks,
        now: DateTime.now(),
        showNow: DateUtils.isSameDay(c.selectedDay, c.today),
        onTap: (rdv) => AppointmentConsultation.showDetail(context, rdv),
        onBlockTap: _openBlock,
      ),
    ];
  }
}

/// « Mardi 10 novembre » + nombre de rendez-vous.
class _DayTitle extends StatelessWidget {
  const _DayTitle({required this.day, required this.count, required this.blocked});

  final DateTime day;
  final int count;
  final int blocked;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: Text(
            toBeginningOfSentenceCase(DateFormat('EEEE d MMMM', 'fr').format(day)),
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
          decoration: BoxDecoration(color: AppColors.primarySurface, borderRadius: BorderRadius.circular(AppRadius.lg)),
          child: Text(
            [
              count == 0 ? 'Aucun rendez-vous' : '$count rendez-vous',
              if (blocked > 0) '$blocked bloqué${blocked > 1 ? 's' : ''}',
            ].join(' · '),
            style: theme.textTheme.labelMedium?.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

/// Passage d'un rendez-vous de l'agenda à son détail, puis à la consultation.
abstract final class AppointmentConsultation {
  /// Raison pour laquelle la consultation ne peut pas être démarrée, ou null si c'est possible.
  ///
  /// Règles : un rendez-vous annulé ou marqué absent ne se démarre pas ; un rendez-vous
  /// à venir ne se démarre que le jour même (ou après, s'il n'a pas été clôturé) ;
  /// un rendez-vous terminé rouvre sa consultation.
  static String? blockedReason(Appointment a, DateTime now) => switch (a.status) {
    AppointmentState.cancelled => 'Ce rendez-vous a été annulé.',
    AppointmentState.noShow => 'Le patient ne s\'est pas présenté à ce rendez-vous.',
    AppointmentState.completed => null,
    AppointmentState.pending || AppointmentState.confirmed =>
      DateUtils.dateOnly(a.dateTime).isAfter(DateUtils.dateOnly(now))
          ? 'La consultation pourra être démarrée le ${DateFormat('d MMMM', 'fr').format(a.dateTime)}, '
              'jour du rendez-vous.'
          : null,
  };

  /// Ouvre le détail du rendez-vous [a] ; au retour, l'agenda et la liste
  /// du patient se rechargent (le rendez-vous a pu passer « Terminé »).
  static Future<void> showDetail(BuildContext context, Appointment a) async {
    await context.push(DoctorRoutes.appointment(a.id!));
    getIt<AppointmentRepository>().changes.value++;
  }
}
