import 'package:medilink/features/appointment/data/models/appointment.dart';
import 'package:medilink/features/appointment/data/models/orientation_result.dart';
import 'package:medilink/features/appointment/data/services/appointment_suggestion_service.dart';

/// Un message de la conversation avec l'assistant d'orientation.
class AssistantMessage {
  const AssistantMessage({
    required this.fromUser,
    required this.text,
    this.orientation,
    this.proposal,
    this.booked,
    this.quickReplies = const [],
  });

  const AssistantMessage.user(this.text)
    : fromUser = true,
      orientation = null,
      proposal = null,
      booked = null,
      quickReplies = const [];

  final bool fromUser;
  final String text;

  /// Résultat de l'analyse des symptômes (carte spécialité / urgence).
  final OrientationResult? orientation;

  /// Rendez-vous proposé, en attente de la réponse du patient.
  final DoctorSuggestion? proposal;

  /// Rendez-vous réservé par l'assistant.
  final Appointment? booked;

  /// Réponses rapides proposées sous le message (boutons).
  final List<String> quickReplies;
}
