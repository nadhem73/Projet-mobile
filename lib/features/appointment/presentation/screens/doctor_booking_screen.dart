import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:medilink/core/di/injection.dart';
import 'package:medilink/core/theme/app_colors.dart';
import 'package:medilink/core/theme/app_dimens.dart';
import 'package:medilink/core/widgets/widgets.dart';
import 'package:medilink/features/appointment/data/models/appointment.dart';
import 'package:medilink/features/appointment/data/models/doctor_summary.dart';
import 'package:medilink/features/appointment/presentation/controllers/booking_controller.dart';
import 'package:medilink/features/appointment/presentation/widgets/doctor_card.dart';

/// Fiche d'un médecin + prise de rendez-vous (jour, heure, motif).
///
/// Revient avec `true` quand un rendez-vous a été réservé.
class DoctorBookingScreen extends StatefulWidget {
  const DoctorBookingScreen({super.key, required this.doctorId});

  final int doctorId;

  @override
  State<DoctorBookingScreen> createState() => _DoctorBookingScreenState();
}

class _DoctorBookingScreenState extends State<DoctorBookingScreen> {
  late final BookingController _controller = getIt<BookingController>(param1: widget.doctorId)..load();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _book() async {
    FocusScope.of(context).unfocus();
    final appointment = await _controller.book();
    if (!mounted) return;
    if (appointment == null) {
      if (_controller.error != null) context.showError(_controller.error!);
      return;
    }
    await _showConfirmation(appointment);
    if (mounted) context.pop(true);
  }

  Future<void> _showConfirmation(Appointment a) => showDialog<void>(
    context: context,
    builder:
        (context) => AlertDialog(
          icon: const Icon(Icons.event_available_rounded, color: AppColors.success, size: 48),
          title: Text(a.status == AppointmentState.confirmed ? 'Rendez-vous confirmé' : 'Demande envoyée'),
          content: Text(
            '${a.doctorName}\n${DateFormat("EEEE d MMMM 'à' HH:mm", 'fr').format(a.dateTime)}',
            textAlign: TextAlign.center,
          ),
          actions: [FilledButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
        ),
  );

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final c = _controller;
        final doctor = c.doctor;
        return Scaffold(
          appBar: AppBar(title: Text(doctor?.fullName ?? 'Prendre rendez-vous')),
          bottomNavigationBar:
              doctor == null
                  ? null
                  : SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.lg),
                      child: MediButton(
                        label:
                            c.selectedSlot == null
                                ? 'Choisissez une heure'
                                : 'Réserver le ${DateFormat("d MMM 'à' HH:mm", 'fr').format(c.selectedSlot!)}',
                        icon: Icons.check_rounded,
                        isLoading: c.isBooking,
                        onPressed: c.canBook ? _book : null,
                      ),
                    ),
                  ),
          body: _body(c, doctor),
        );
      },
    );
  }

  Widget _body(BookingController c, DoctorSummary? doctor) {
    if (c.isLoading) return const LoadingView();
    if (doctor == null) {
      return EmptyState.error(c.error ?? 'Médecin introuvable', onRetry: c.load);
    }
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        _DoctorHeader(doctor: doctor),
        const SizedBox(height: AppSpacing.xl),
        Text('Choisissez un jour', style: theme.textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        if (c.days.isEmpty)
          const Text("Ce médecin n'a pas d'horaires de consultation renseignés.")
        else
          _BookingCalendar(days: c.days, selectedDay: c.selectedDay, onSelected: c.selectDay),
        const SizedBox(height: AppSpacing.xl),
        Text('Heures disponibles', style: theme.textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        if (c.isLoadingSlots)
          const Padding(padding: EdgeInsets.all(AppSpacing.lg), child: Center(child: CircularProgressIndicator()))
        else if (c.selectedDay != null && c.slots.isEmpty)
          Text('Plus aucun créneau libre ce jour-là. Choisissez un autre jour.', style: theme.textTheme.bodyMedium)
        else
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final slot in c.slots)
                ChoiceChip(
                  label: Text(DateFormat('HH:mm').format(slot)),
                  selected: c.selectedSlot == slot,
                  onSelected: (_) => c.selectSlot(slot),
                ),
            ],
          ),
        const SizedBox(height: AppSpacing.xl),
        Text('Motif (facultatif)', style: theme.textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          onChanged: c.setReason,
          maxLines: 2,
          maxLength: 200,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(hintText: 'Ex. contrôle, douleur, renouvellement d\'ordonnance…'),
        ),
      ],
    );
  }
}

class _DoctorHeader extends StatelessWidget {
  const _DoctorHeader({required this.doctor});

  final DoctorSummary doctor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final d = doctor;
    return MediCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              MediAvatar(initials: d.initials, size: 64, color: AppColors.moduleAppointment),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(d.fullName, style: theme.textTheme.titleLarge),
                    const SizedBox(height: 2),
                    Text(d.specialty, style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.moduleAppointment)),
                  ],
                ),
              ),
            ],
          ),
          if (d.biography != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(d.biography!, style: theme.textTheme.bodyMedium),
          ],
          const SizedBox(height: AppSpacing.sm),
          if (d.address != null || d.city != null)
            InfoRow(
              icon: Icons.place_outlined,
              label: 'Adresse',
              value: [
                d.address,
                if (d.address == null || !d.address!.contains(d.city ?? '')) d.city,
              ].whereType<String>().join(', '),
            ),
          if (d.fee != null) InfoRow(icon: Icons.payments_outlined, label: 'Consultation', value: formatFee(d.fee!)),
        ],
      ),
    );
  }
}

/// Calendrier mensuel : seuls les jours où le médecin consulte (dans les 30 prochains jours)
/// sont cliquables, les autres sont grisés.
class _BookingCalendar extends StatelessWidget {
  const _BookingCalendar({required this.days, required this.selectedDay, required this.onSelected});

  final List<DateTime> days;
  final DateTime? selectedDay;
  final ValueChanged<DateTime> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final open = {for (final d in days) DateUtils.dateOnly(d)};
    return MediCard(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Column(
        children: [
          Theme(
            // Jour choisi aux couleurs du module Rendez-vous.
            data: theme.copyWith(colorScheme: theme.colorScheme.copyWith(primary: AppColors.moduleAppointment)),
            child: CalendarDatePicker(
              initialDate: selectedDay ?? days.first,
              firstDate: days.first,
              lastDate: days.last,
              selectableDayPredicate: (d) => open.contains(DateUtils.dateOnly(d)),
              onDateChanged: onSelected,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.sm),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, size: 16, color: AppColors.textMuted),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    'Jours grisés : le médecin ne consulte pas.',
                    style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
