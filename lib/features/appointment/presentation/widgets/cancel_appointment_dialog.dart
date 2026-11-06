import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:medilink/core/theme/app_colors.dart';
import 'package:medilink/features/appointment/data/models/appointment.dart';

/// Demande confirmation avant d'annuler un rendez-vous. Renvoie `true` si le patient confirme.
Future<bool> confirmCancelAppointment(BuildContext context, Appointment a) async {
  final confirm = await showDialog<bool>(
    context: context,
    builder:
        (context) => AlertDialog(
          title: const Text('Annuler ce rendez-vous ?'),
          content: Text(
            '${a.doctorName}\n${DateFormat("EEEE d MMMM 'à' HH:mm", 'fr').format(a.dateTime)}\n\n'
            'Le créneau sera libéré et le médecin sera prévenu.',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Garder')),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.error),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Annuler le rendez-vous'),
            ),
          ],
        ),
  );
  return confirm ?? false;
}
