import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:medilink/core/di/injection.dart';
import 'package:medilink/core/theme/app_dimens.dart';
import 'package:medilink/core/widgets/widgets.dart';
import 'package:medilink/features/doctor/doctor_module.dart';
import 'package:medilink/features/doctor/presentation/controllers/prescriptions_controller.dart';
import 'package:medilink/features/doctor/presentation/widgets/prescription_tile.dart';

/// Ordonnances de l'utilisateur connecté : reçues (patient) ou rédigées (médecin).
class PrescriptionsScreen extends StatefulWidget {
  const PrescriptionsScreen({super.key, this.embedded = false});

  /// Affiché comme onglet du panel médecin (pas de bouton retour).
  final bool embedded;

  @override
  State<PrescriptionsScreen> createState() => _PrescriptionsScreenState();
}

class _PrescriptionsScreenState extends State<PrescriptionsScreen> {
  final _controller = getIt<PrescriptionsController>()..load();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDoctor = _controller.isDoctor;
    return Scaffold(
      appBar: AppBar(
        title: Text(isDoctor ? 'Ordonnances rédigées' : 'Mes ordonnances'),
        automaticallyImplyLeading: !widget.embedded,
      ),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          if (_controller.isLoading && _controller.prescriptions.isEmpty) return const LoadingView();
          if (_controller.error != null) return EmptyState.error(_controller.error!, onRetry: _controller.load);
          final list = _controller.prescriptions;
          return RefreshIndicator(
            onRefresh: _controller.load,
            child:
                list.isEmpty
                    ? ListView(
                      children: [
                        SizedBox(
                          height: 420,
                          child: EmptyState(
                            icon: Icons.receipt_long_outlined,
                            title: 'Aucune ordonnance',
                            message:
                                isDoctor
                                    ? 'Rédigez une ordonnance depuis une consultation en cours.'
                                    : 'Les ordonnances de vos médecins apparaîtront ici après vos consultations.',
                          ),
                        ),
                      ],
                    )
                    : ListView.separated(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      itemCount: list.length,
                      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
                      itemBuilder:
                          (context, i) => PrescriptionTile(
                            prescription: list[i],
                            showPatient: isDoctor,
                            showDoctor: !isDoctor,
                            onTap: () => context.push(DoctorRoutes.prescription(list[i].id)),
                          ),
                    ),
          );
        },
      ),
    );
  }
}
