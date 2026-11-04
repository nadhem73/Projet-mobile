import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:medilink/core/di/injection.dart';
import 'package:medilink/core/theme/app_dimens.dart';
import 'package:medilink/core/widgets/widgets.dart';
import 'package:medilink/features/appointment/appointment_module.dart';
import 'package:medilink/features/appointment/data/models/appointment.dart';
import 'package:medilink/features/appointment/presentation/controllers/my_appointments_controller.dart';
import 'package:medilink/features/appointment/presentation/widgets/appointment_card.dart';
import 'package:medilink/features/appointment/presentation/widgets/cancel_appointment_dialog.dart';

/// « Mes rendez-vous » du patient connecté : onglets À venir / Passés.
///
/// Utilisé comme onglet du panel patient et comme page (route [AppointmentRoutes.list]).
class MyAppointmentsScreen extends StatefulWidget {
  const MyAppointmentsScreen({super.key});

  @override
  State<MyAppointmentsScreen> createState() => _MyAppointmentsScreenState();
}

class _MyAppointmentsScreenState extends State<MyAppointmentsScreen> {
  late final MyAppointmentsController _controller = getIt<MyAppointmentsController>()..load();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Ouvre la recherche de médecin, puis recharge la liste au retour (un rendez-vous a pu être pris).
  Future<void> _book() async {
    await context.push(AppointmentRoutes.doctors);
    if (mounted) await _controller.load();
  }

  Future<void> _cancel(Appointment a) async {
    if (!await confirmCancelAppointment(context, a)) return;
    final error = await _controller.cancel(a.id!);
    if (!mounted) return;
    error == null ? context.showSuccess('Rendez-vous annulé') : context.showError(error);
  }

  void _open(Appointment a) => context.push(AppointmentRoutes.appointment(a.id!));

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Mes rendez-vous'),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(kTextTabBarHeight),
            child: ListenableBuilder(
              listenable: _controller,
              builder:
                  (context, _) => TabBar(
                    tabs: [
                      Tab(text: _controller.upcoming.isEmpty ? 'À venir' : 'À venir (${_controller.upcoming.length})'),
                      const Tab(text: 'Passés'),
                    ],
                  ),
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          heroTag: 'book-appointment',
          onPressed: _book,
          icon: const Icon(Icons.add_rounded),
          label: const Text('Prendre rendez-vous'),
        ),
        body: ListenableBuilder(
          listenable: _controller,
          builder: (context, _) {
            if (_controller.isLoading && _controller.upcoming.isEmpty && _controller.past.isEmpty) {
              return const LoadingView();
            }
            if (_controller.error != null) {
              return EmptyState.error(_controller.error!, onRetry: _controller.load);
            }
            return TabBarView(
              children: [
                _AppointmentList(
                  appointments: _controller.upcoming,
                  onRefresh: _controller.load,
                  onOpen: _open,
                  onCancel: _cancel,
                  empty: EmptyState(
                    icon: Icons.event_available_rounded,
                    title: 'Aucun rendez-vous à venir',
                    message: 'Trouvez un médecin et réservez un créneau en quelques secondes.',
                    actionLabel: 'Prendre rendez-vous',
                    onAction: _book,
                  ),
                ),
                _AppointmentList(
                  appointments: _controller.past,
                  onRefresh: _controller.load,
                  onOpen: _open,
                  empty: const EmptyState(
                    icon: Icons.history_rounded,
                    title: 'Aucun rendez-vous passé',
                    message: 'Vos rendez-vous terminés et annulés apparaîtront ici.',
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _AppointmentList extends StatelessWidget {
  const _AppointmentList({
    required this.appointments,
    required this.onRefresh,
    required this.empty,
    required this.onOpen,
    this.onCancel,
  });

  final List<Appointment> appointments;
  final Future<void> Function() onRefresh;
  final Widget empty;
  final ValueChanged<Appointment> onOpen;
  final ValueChanged<Appointment>? onCancel;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child:
          appointments.isEmpty
              // Défilable pour que « tirer pour actualiser » fonctionne aussi sur une liste vide.
              ? LayoutBuilder(
                builder:
                    (context, constraints) => SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: SizedBox(height: constraints.maxHeight, child: empty),
                    ),
              )
              : ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 96),
                itemCount: appointments.length,
                separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
                itemBuilder: (context, i) {
                  final a = appointments[i];
                  return AppointmentCard(
                    appointment: a,
                    onTap: () => onOpen(a),
                    onCancel: onCancel == null ? null : () => onCancel!(a),
                  );
                },
              ),
    );
  }
}
