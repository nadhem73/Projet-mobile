import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:medilink/core/error/app_exception.dart';
import 'package:medilink/core/session/session_service.dart';
import 'package:medilink/features/appointment/data/models/appointment.dart';
import 'package:medilink/features/appointment/data/models/assistant_message.dart';
import 'package:medilink/features/appointment/data/models/orientation_result.dart';
import 'package:medilink/features/appointment/data/repositories/appointment_repository.dart';
import 'package:medilink/features/appointment/data/services/appointment_suggestion_service.dart';
import 'package:medilink/features/appointment/data/services/orientation_engine.dart';
import 'package:medilink/features/appointment/data/services/symptom_analyzer.dart';

/// Où en est la conversation.
enum AssistantStep {
  /// L'assistant attend la description des symptômes.
  askSymptoms,

  /// Un rendez-vous est proposé : l'assistant attend « oui », « non », « autre créneau »...
  awaitingConfirmation,

  /// Le rendez-vous a été réservé.
  booked,

  /// Urgence détectée : orientation vers le 190, aucun rendez-vous.
  emergency,
}

/// Ce que le patient répond à une proposition de rendez-vous.
enum ReplyIntent { yes, no, otherSlot, otherDoctor, unknown }

/// Conversation avec l'assistant d'orientation :
/// symptômes → spécialité → proposition d'un rendez-vous → réservation si le patient accepte.
class OrientationAssistantController extends ChangeNotifier {
  OrientationAssistantController(this._analyzer, this._engine, this._suggestions, this._appointments, this._session);

  /// Analyse rapide hors ligne (sert aussi à repérer de nouveaux symptômes dans une réponse).
  final SymptomAnalyzer _analyzer;

  /// Analyse complète : LLM en ligne si configuré, sinon hors ligne.
  final OrientationEngine _engine;
  final AppointmentSuggestionService _suggestions;
  final AppointmentRepository _appointments;
  final SessionService _session;

  final List<AssistantMessage> messages = [];
  AssistantStep step = AssistantStep.askSymptoms;

  /// L'assistant « réfléchit » (analyse, recherche de créneaux, réservation).
  bool isBusy = false;

  // Contexte de la proposition en cours.
  String _symptoms = '';
  SuggestionResult _result = SuggestionResult.none;
  int _doctorIndex = 0;
  DoctorSuggestion? _current;

  // Réponses rapides.
  static const yesReply = 'Oui, réservez';
  static const otherSlotReply = 'Un autre créneau';
  static const otherDoctorReply = 'Un autre médecin';
  static const noReply = 'Non merci';
  static const newQuestionReply = 'Décrire d\'autres symptômes';

  static final _date = DateFormat("EEEE d MMMM 'à' HH:mm", 'fr');

  /// Message d'accueil.
  void start() {
    if (messages.isNotEmpty) return;
    final prenom = _session.currentUser?.prenom;
    _say(
      'Bonjour${prenom == null ? '' : ' $prenom'} 👋 Je suis l\'assistant MediLink.\n'
      'Décrivez-moi vos symptômes (ce que vous ressentez, depuis quand) et je vous dirai quel '
      'spécialiste consulter. Je peux aussi vous prendre rendez-vous.',
    );
    notifyListeners();
  }

  /// Le patient envoie un message (texte libre ou réponse rapide).
  Future<void> send(String input) async {
    final text = input.trim();
    if (text.isEmpty || isBusy) return;
    messages.add(AssistantMessage.user(text));
    isBusy = true;
    notifyListeners();
    try {
      if (step == AssistantStep.awaitingConfirmation) {
        await _handleReply(text);
      } else if (text == newQuestionReply) {
        _askSymptomsAgain();
      } else {
        await _analyze(text);
      }
    } catch (e) {
      debugPrint('[OrientationAssistantController] $e');
      _say('Désolé, une erreur est survenue. Pouvez-vous reformuler ?');
      step = AssistantStep.askSymptoms;
    } finally {
      isBusy = false;
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------------------
  // 1. Analyse des symptômes
  // ---------------------------------------------------------------------------

  Future<void> _analyze(String symptoms) async {
    _symptoms = symptoms;
    final orientation = await _engine.analyze(symptoms);

    if (orientation.isEmergency) {
      step = AssistantStep.emergency;
      _say(
        '⚠️ ${orientation.summary}\nSignes repérés : ${orientation.redFlags.join(', ')}.\n'
        'Je ne prends pas de rendez-vous dans ce cas : votre sécurité passe avant tout.',
        orientation: orientation,
        quickReplies: const [newQuestionReply],
      );
      return;
    }

    final why = orientation.reasons.isEmpty ? '' : ' (${orientation.reasons.join(', ')})';
    _say('${orientation.summary}$why', orientation: orientation);

    _result = await _suggestions.suggest(orientation, city: null);
    _doctorIndex = 0;
    if (_result.isEmpty) {
      step = AssistantStep.askSymptoms;
      _say(
        'Je n\'ai trouvé aucun médecin disponible pour le moment. '
        'Vous pouvez réessayer plus tard ou chercher vous-même dans « Trouver un médecin ».',
        quickReplies: const [newQuestionReply],
      );
      return;
    }
    if (_result.usedFallback) {
      _say(
        'Aucun médecin en ${orientation.specialty} n\'est disponible sur MediLink pour le moment. '
        'Un médecin généraliste peut vous recevoir et vous orienter.',
      );
    }
    _propose(_result.suggestions.first);
  }

  // ---------------------------------------------------------------------------
  // 2. Proposition et réponse du patient
  // ---------------------------------------------------------------------------

  void _propose(DoctorSuggestion suggestion) {
    _current = suggestion;
    step = AssistantStep.awaitingConfirmation;
    final d = suggestion.doctor;
    final where = d.city == null ? d.specialty : '${d.specialty}, ${d.city}';
    _say(
      'Voulez-vous que je vous prenne rendez-vous avec ${d.fullName} ($where) '
      'le ${_date.format(suggestion.firstSlot)} ?',
      proposal: suggestion,
      quickReplies: [yesReply, otherSlotReply, if (_result.suggestions.length > 1) otherDoctorReply, noReply],
    );
  }

  Future<void> _handleReply(String text) async {
    switch (parseReply(text)) {
      case ReplyIntent.yes:
        await _book();
      case ReplyIntent.otherSlot:
        await _proposeNextSlot();
      case ReplyIntent.otherDoctor:
        _proposeNextDoctor();
      case ReplyIntent.no:
        step = AssistantStep.askSymptoms;
        _current = null;
        _say(
          'D\'accord, je ne réserve rien. Vous pouvez prendre rendez-vous plus tard depuis « Trouver un médecin », '
          'ou me décrire d\'autres symptômes.',
        );
      case ReplyIntent.unknown:
        // Le patient décrit peut-être de nouveaux symptômes au lieu de répondre.
        final orientation = _analyzer.analyze(text);
        if (orientation.isEmergency || orientation.reasons.isNotEmpty) {
          step = AssistantStep.askSymptoms;
          await _analyze(text);
        } else {
          _say(
            'Je n\'ai pas compris. Voulez-vous que je réserve ce rendez-vous ? Répondez « oui » ou « non ».',
            quickReplies: _lastQuickReplies,
          );
        }
    }
  }

  Future<void> _proposeNextSlot() async {
    final current = _current!;
    final next = await _suggestions.firstAvailableSlot(
      current.doctor.doctorId,
      days: AppointmentSuggestionService.daysToSearch(OrientationUrgency.routine),
      after: current.firstSlot,
    );
    if (next == null) {
      _say(
        '${current.doctor.fullName} n\'a pas d\'autre créneau libre dans les 30 prochains jours.',
        quickReplies: _lastQuickReplies,
      );
      return;
    }
    _propose(DoctorSuggestion(doctor: current.doctor, firstSlot: next));
  }

  void _proposeNextDoctor() {
    if (_doctorIndex + 1 >= _result.suggestions.length) {
      _say('Je n\'ai pas d\'autre médecin à vous proposer dans cette spécialité.', quickReplies: _lastQuickReplies);
      return;
    }
    _doctorIndex++;
    _propose(_result.suggestions[_doctorIndex]);
  }

  // ---------------------------------------------------------------------------
  // 3. Réservation
  // ---------------------------------------------------------------------------

  Future<void> _book() async {
    final proposal = _current!;
    final patientId = _session.currentUser?.patientId;
    if (patientId == null) {
      step = AssistantStep.askSymptoms;
      _say('Seul un patient connecté peut prendre rendez-vous.');
      return;
    }
    try {
      final appointment = await _appointments.book(
        patientId: patientId,
        doctorId: proposal.doctor.doctorId,
        dateTime: proposal.firstSlot,
        reason: reasonFor(_symptoms),
      );
      step = AssistantStep.booked;
      _current = null;
      _say(
        'C\'est fait ✅ Rendez-vous confirmé avec ${appointment.doctorName} '
        'le ${_date.format(appointment.dateTime)}.\nVous le retrouverez dans l\'onglet « Rendez-vous ».',
        booked: appointment,
        quickReplies: const [newQuestionReply],
      );
    } on AppException catch (e) {
      // Créneau pris entre-temps : on propose le suivant chez le même médecin.
      _say('${e.message} Je cherche un autre créneau…');
      await _proposeNextSlot();
    }
  }

  // ---------------------------------------------------------------------------

  void _askSymptomsAgain() {
    step = AssistantStep.askSymptoms;
    _current = null;
    _say('Je vous écoute : décrivez-moi vos symptômes.');
  }

  List<String> get _lastQuickReplies =>
      messages
          .lastWhere(
            (m) => !m.fromUser && m.quickReplies.isNotEmpty,
            orElse: () => const AssistantMessage(fromUser: false, text: ''),
          )
          .quickReplies;

  void _say(
    String text, {
    OrientationResult? orientation,
    DoctorSuggestion? proposal,
    Appointment? booked,
    List<String> quickReplies = const [],
  }) {
    messages.add(
      AssistantMessage(
        fromUser: false,
        text: text,
        orientation: orientation,
        proposal: proposal,
        booked: booked,
        quickReplies: quickReplies,
      ),
    );
  }

  /// Motif enregistré avec le rendez-vous : les symptômes décrits (200 caractères max).
  static String reasonFor(String symptoms) {
    final s = symptoms.replaceAll(RegExp(r'\s+'), ' ').trim();
    final text = 'Assistant IA : $s';
    return text.length <= 200 ? text : '${text.substring(0, 199)}…';
  }

  /// Comprend la réponse du patient à une proposition (texte libre ou bouton).
  static ReplyIntent parseReply(String input) {
    final t = SymptomAnalyzer.normalize(input).replaceAll(RegExp(r'[!?.,;:]'), ' ');
    final words = t.split(' ').where((w) => w.isNotEmpty).toSet();
    bool has(String phrase) => phrase.contains(' ') ? t.contains(phrase) : words.contains(phrase);

    if (has('autre medecin') || has('autre docteur') || has('quelqu\'un d\'autre') || has('autre specialiste')) {
      return ReplyIntent.otherDoctor;
    }
    if (has('autre creneau') ||
        has('autre heure') ||
        has('autre jour') ||
        has('autre date') ||
        has('plus tard') ||
        has('pas a cette heure') ||
        has('pas ce jour')) {
      return ReplyIntent.otherSlot;
    }
    const no = ['non', 'nan', 'annule', 'annuler', 'laisse', 'stop'];
    if (no.any(words.contains) || has('pas maintenant') || has('pas besoin') || has('non merci')) {
      return ReplyIntent.no;
    }
    const yes = ['oui', 'ok', 'okay', 'ouais', 'daccord', 'parfait', 'yes', 'reservez', 'reserve', 'confirme', 'go'];
    if (yes.any(words.contains) ||
        has('d\'accord') ||
        has('vas-y') ||
        has('vas y') ||
        has('c\'est bon') ||
        has('ca marche')) {
      return ReplyIntent.yes;
    }
    return ReplyIntent.unknown;
  }
}
