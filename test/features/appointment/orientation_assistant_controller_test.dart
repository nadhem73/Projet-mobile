import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:medilink/core/database/app_database.dart';
import 'package:medilink/core/notifications/notification_service.dart';
import 'package:medilink/core/session/current_user.dart';
import 'package:medilink/core/session/session_service.dart';
import 'package:medilink/core/session/user_role.dart';
import 'package:medilink/features/appointment/data/repositories/appointment_repository.dart';
import 'package:medilink/features/appointment/data/repositories/doctor_search_repository.dart';
import 'package:medilink/features/appointment/data/services/appointment_suggestion_service.dart';
import 'package:medilink/features/appointment/data/services/orientation_engine.dart';
import 'package:medilink/features/appointment/data/services/symptom_analyzer.dart';
import 'package:medilink/features/appointment/presentation/controllers/orientation_assistant_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

typedef C = OrientationAssistantController;

void main() {
  sqfliteFfiInit();
  late AppDatabase database;
  late AppointmentRepository appointments;
  late OrientationAssistantController assistant;
  late int patientId;

  setUpAll(() => initializeDateFormatting('fr'));

  setUp(() async {
    database = await AppDatabase.open(factory: databaseFactoryFfi, path: inMemoryDatabasePath);
    final doctors = DoctorSearchRepository(database);
    appointments = AppointmentRepository(database, doctors, NotificationService(database));

    final patient =
        (await database.db.rawQuery(
          "SELECT u.id, u.nom, u.prenom, p.patient_id FROM users u JOIN patients p ON p.user_id = u.id "
          "WHERE u.email = 'patient@medilink.tn'",
        )).first;
    patientId = patient['patient_id'] as int;
    SharedPreferences.setMockInitialValues({});
    final session = SessionService(await SharedPreferences.getInstance());
    await session.open(
      CurrentUser(
        userId: patient['id'] as int,
        role: UserRole.patient,
        nom: patient['nom'] as String,
        prenom: patient['prenom'] as String,
        email: 'patient@medilink.tn',
        patientId: patientId,
      ),
    );

    assistant = OrientationAssistantController(
      const SymptomAnalyzer(),
      const OrientationEngine(SymptomAnalyzer(), null),
      AppointmentSuggestionService(doctors, appointments),
      appointments,
      session,
    )..start();
  });

  tearDown(() => database.close());

  String lastText() => assistant.messages.last.text;

  group('compréhension des réponses', () {
    test('oui / non / autre créneau / autre médecin', () {
      expect(C.parseReply('Oui, réservez'), ReplyIntent.yes);
      expect(C.parseReply("d'accord"), ReplyIntent.yes);
      expect(C.parseReply('OK vas-y'), ReplyIntent.yes);
      expect(C.parseReply('Non merci'), ReplyIntent.no);
      expect(C.parseReply('pas maintenant'), ReplyIntent.no);
      expect(C.parseReply('Un autre créneau'), ReplyIntent.otherSlot);
      expect(C.parseReply('plutôt plus tard'), ReplyIntent.otherSlot);
      expect(C.parseReply('Un autre médecin'), ReplyIntent.otherDoctor);
      expect(C.parseReply('euh je sais pas'), ReplyIntent.unknown);
      // « ok » ne doit pas être trouvé dans « okra », ni « non » dans « nonchalant ».
      expect(C.parseReply('nonchalant'), ReplyIntent.unknown);
    });

    test('motif enregistré avec le rendez-vous', () {
      expect(C.reasonFor('  J\'ai   des palpitations '), "Assistant IA : J'ai des palpitations");
      expect(C.reasonFor('a' * 300).length, 200);
    });
  });

  test('accueil personnalisé', () {
    expect(assistant.messages.single.text, startsWith('Bonjour'));
    expect(assistant.step, AssistantStep.askSymptoms);
  });

  test('symptômes → proposition → « oui » → rendez-vous réservé', () async {
    final before = (await appointments.upcomingForPatient(patientId)).length;

    await assistant.send("J'ai des palpitations et je m'essouffle vite quand je monte les escaliers");
    expect(assistant.step, AssistantStep.awaitingConfirmation);
    final proposal = assistant.messages.last.proposal!;
    expect(proposal.doctor.nom, 'Benali');
    expect(lastText(), contains('Voulez-vous que je vous prenne rendez-vous avec Dr Sami Benali'));
    expect(assistant.messages.last.quickReplies, contains(C.yesReply));
    expect(assistant.messages.any((m) => m.orientation?.specialty == 'Cardiologie'), isTrue);

    await assistant.send('oui');
    expect(assistant.step, AssistantStep.booked);
    final booked = assistant.messages.last.booked!;
    expect(booked.dateTime, proposal.firstSlot);
    expect(lastText(), startsWith("C'est fait"));

    final upcoming = await appointments.upcomingForPatient(patientId);
    expect(upcoming, hasLength(before + 1));
    expect(upcoming.firstWhere((a) => a.id == booked.id).reason, startsWith('Assistant IA : '));
  });

  test('« un autre créneau » propose une heure plus tardive chez le même médecin', () async {
    await assistant.send("J'ai des boutons et ça me gratte");
    final first = assistant.messages.last.proposal!;

    await assistant.send(C.otherSlotReply);
    final second = assistant.messages.last.proposal!;
    expect(second.doctor.doctorId, first.doctor.doctorId);
    expect(second.firstSlot.isAfter(first.firstSlot), isTrue);
    expect(assistant.step, AssistantStep.awaitingConfirmation);
  });

  test('« un autre médecin » quand il n\'y en a qu\'un', () async {
    await assistant.send("J'ai des boutons et ça me gratte");
    await assistant.send(C.otherDoctorReply);
    expect(lastText(), contains("pas d'autre médecin"));
    expect(assistant.step, AssistantStep.awaitingConfirmation);
  });

  test('« non » : rien n\'est réservé', () async {
    final before = (await appointments.upcomingForPatient(patientId)).length;
    await assistant.send("J'ai mal à la gorge");
    await assistant.send('non merci');
    expect(assistant.step, AssistantStep.askSymptoms);
    expect(lastText(), contains('je ne réserve rien'));
    expect(await appointments.upcomingForPatient(patientId), hasLength(before));
  });

  test('réponse incomprise : l\'assistant redemande', () async {
    await assistant.send("J'ai mal à la gorge");
    await assistant.send('hmm');
    expect(lastText(), contains('Répondez « oui » ou « non »'));
    expect(assistant.step, AssistantStep.awaitingConfirmation);
  });

  test('nouveaux symptômes au lieu de répondre : nouvelle analyse', () async {
    await assistant.send("J'ai mal à la gorge");
    await assistant.send("En fait j'ai surtout des palpitations");
    expect(assistant.messages.last.proposal!.doctor.specialty, 'Cardiologie');
  });

  test('urgence : 190, aucune proposition de rendez-vous', () async {
    await assistant.send("J'ai une très forte douleur dans la poitrine");
    expect(assistant.step, AssistantStep.emergency);
    expect(lastText(), contains('190'));
    expect(assistant.messages.every((m) => m.proposal == null), isTrue);

    await assistant.send(C.newQuestionReply);
    expect(assistant.step, AssistantStep.askSymptoms);
  });

  test('créneau pris entre-temps : l\'assistant en propose un autre', () async {
    await assistant.send("J'ai des boutons et ça me gratte");
    final proposal = assistant.messages.last.proposal!;

    // Un autre patient réserve ce créneau juste avant.
    final otherPatient = await database.db.insert('patients', {
      'user_id': await database.db.insert('users', {
        'nom': 'Autre',
        'prenom': 'Patient',
        'email': 'autre@medilink.tn',
        'password_hash': 'x',
        'role': 'PATIENT',
      }),
    });
    await appointments.book(patientId: otherPatient, doctorId: proposal.doctor.doctorId, dateTime: proposal.firstSlot);

    await assistant.send('oui');
    expect(assistant.step, AssistantStep.awaitingConfirmation);
    expect(assistant.messages.last.proposal!.firstSlot.isAfter(proposal.firstSlot), isTrue);
  });
}
