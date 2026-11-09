import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../data/models/medicine.dart';
import '../../data/models/pharmacy_stock.dart';
import '../../data/repositories/medicine_repository.dart';
import '../../data/repositories/stock_repository.dart';
import '../../data/services/pharmacy_voice_nlp_service.dart';

/// Action de modification en attente de confirmation explicite du pharmacien.
class PendingStockAction {
  final VoiceParseResult parsedResult;
  final PharmacyStock currentStock;
  final PharmacyStock updatedStock;
  final String confirmationQuestion;
  final String confirmationSpoken;
  final String successSpoken;

  const PendingStockAction({
    required this.parsedResult,
    required this.currentStock,
    required this.updatedStock,
    required this.confirmationQuestion,
    required this.confirmationSpoken,
    required this.successSpoken,
  });
}

class PharmacyVoiceAssistantController extends ChangeNotifier {
  PharmacyVoiceAssistantController({
    required this.pharmacyId,
    required StockRepository stockRepository,
    required MedicineRepository medicineRepository,
    PharmacyVoiceNLPService? nlpService,
    stt.SpeechToText? speechToText,
    FlutterTts? flutterTts,
  })  : _stockRepository = stockRepository,
        _medicineRepository = medicineRepository,
        _nlpService = nlpService ?? PharmacyVoiceNLPService(),
        _speechToText = speechToText ?? stt.SpeechToText(),
        _flutterTts = flutterTts ?? FlutterTts();

  final int pharmacyId;
  final StockRepository _stockRepository;
  final MedicineRepository _medicineRepository;
  final PharmacyVoiceNLPService _nlpService;
  final stt.SpeechToText _speechToText;
  final FlutterTts _flutterTts;

  // État
  bool _isInitialized = false;
  bool _isSpeechAvailable = false;
  bool _isListening = false;
  bool _isProcessing = false;
  bool _isSpeaking = false;
  bool _isTtsEnabled = true;
  String _voiceTranscript = '';
  String? _speechError;
  VoiceParseResult? _lastResult;

  // Cache des données pour analyse ultra-rapide
  List<PharmacyStockItem> _stockItems = [];
  List<Medicine> _allMedicines = [];

  // Support Undo
  PharmacyStock? _undoStock;

  // Action en attente de confirmation
  PendingStockAction? _pendingAction;

  // Getters
  bool get isListening => _isListening;
  bool get isProcessing => _isProcessing;
  bool get isSpeaking => _isSpeaking;
  bool get isTtsEnabled => _isTtsEnabled;
  bool get isSpeechAvailable => _isSpeechAvailable;
  String get voiceTranscript => _voiceTranscript;
  String? get speechError => _speechError;
  VoiceParseResult? get lastResult => _lastResult;
  bool get canUndo => _undoStock != null;
  PendingStockAction? get pendingAction => _pendingAction;
  bool get hasPendingAction => _pendingAction != null;

  /// Initialise les moteurs de voix et charge le stock de l'officine
  Future<void> initialize() async {
    if (_isInitialized) return;

    // 1. Charger les médicaments et le stock
    await refreshStockData();

    // 2. Initialiser Text-To-Speech avec le moteur Google TTS haute fidélité
    try {
      // Activer explicitement le moteur Google Text-To-Speech
      final engines = await _flutterTts.getEngines;
      if (engines is List && engines.contains('com.google.android.tts')) {
        await _flutterTts.setEngine('com.google.android.tts');
      }

      await _flutterTts.setLanguage('fr-FR');

      // Sélectionner la meilleure voix Google neuronale / HD en français
      try {
        final dynamic voices = await _flutterTts.getVoices;
        if (voices is List) {
          Map<String, String>? bestVoice;
          for (final v in voices) {
            if (v is Map) {
              final locale = (v['locale'] ?? '').toString();
              final name = (v['name'] ?? '').toString().toLowerCase();
              if (locale.startsWith('fr') || locale.contains('FR')) {
                // Voix neuronales Google (WaveNet / Neural / HD)
                if (name.contains('neural') ||
                    name.contains('network') ||
                    name.contains('vda') ||
                    name.contains('frd') ||
                    name.contains('frc') ||
                    name.contains('fr-fr-x')) {
                  bestVoice = {
                    'name': (v['name'] ?? '').toString(),
                    'locale': locale,
                  };
                  break;
                }
                bestVoice ??= {
                  'name': (v['name'] ?? '').toString(),
                  'locale': locale,
                };
              }
            }
          }
          if (bestVoice != null) {
            await _flutterTts.setVoice(bestVoice);
            debugPrint('[VoiceAssistant] Voix Google sélectionnée: ${bestVoice['name']}');
          }
        }
      } catch (voiceError) {
        debugPrint('[VoiceAssistant] Voix par défaut conservée: $voiceError');
      }

      // Cadence et tonalité naturelles (voix humaine chaleureuse)
      await _flutterTts.setSpeechRate(0.48);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.02);
      _flutterTts.setStartHandler(() {
        _isSpeaking = true;
        notifyListeners();
      });
      _flutterTts.setCompletionHandler(() {
        _isSpeaking = false;
        notifyListeners();
      });
      _flutterTts.setErrorHandler((msg) {
        _isSpeaking = false;
        notifyListeners();
      });
    } catch (e) {
      debugPrint('[VoiceAssistant] Erreur TTS: $e');
    }

    // 3. Initialiser Speech-to-Text
    try {
      _isSpeechAvailable = await _speechToText.initialize(
        onError: (val) {
          _speechError = val.errorMsg;
          _isListening = false;
          notifyListeners();
        },
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
            _isListening = false;
            notifyListeners();
          }
        },
      );
    } catch (e) {
      debugPrint('[VoiceAssistant] Erreur STT: $e');
      _isSpeechAvailable = false;
    }

    _isInitialized = true;
    notifyListeners();
  }

  /// Recharge les données d'officine
  Future<void> refreshStockData() async {
    try {
      final stocks = await _stockRepository.getByPharmacy(pharmacyId);
      final medicines = await _medicineRepository.getAll(limit: 9999);
      _allMedicines = medicines;

      final medMap = {for (final m in medicines) m.medicineId ?? 0: m};
      final items = <PharmacyStockItem>[];
      for (final s in stocks) {
        final med = medMap[s.medicineId];
        if (med != null) {
          items.add(PharmacyStockItem(medicine: med, stock: s));
        }
      }
      _stockItems = items;
    } catch (e) {
      debugPrint('[VoiceAssistant] Erreur refresh: $e');
    }
  }

  /// Démarre l'écoute vocale
  Future<void> startListening() async {
    _speechError = null;
    _voiceTranscript = '';
    _lastResult = null;
    notifyListeners();

    if (!_isSpeechAvailable) {
      // Tenter une réinitialisation
      try {
        _isSpeechAvailable = await _speechToText.initialize();
      } catch (_) {}
    }

    if (!_isSpeechAvailable) {
      _speechError =
          'Reconnaissance vocale non disponible sur cet appareil. Vous pouvez saisir votre commande au clavier.';
      notifyListeners();
      return;
    }

    // Stopper toute lecture vocale en cours
    await stopSpeaking();

    _isListening = true;
    notifyListeners();

    try {
      await _speechToText.listen(
        onResult: (result) {
          _voiceTranscript = result.recognizedWords;
          notifyListeners();

          if (result.finalResult && _voiceTranscript.isNotEmpty) {
            _isListening = false;
            processCommand(_voiceTranscript);
          }
        },
        listenOptions: stt.SpeechListenOptions(
          localeId: 'fr_FR',
          listenFor: const Duration(seconds: 45), // Écoute prolongée (45s)
          pauseFor: const Duration(seconds: 7),   // Tolérance aux pauses de parole (7s)
          cancelOnError: false,
          partialResults: true,
        ),
      );
    } catch (e) {
      _isListening = false;
      _speechError = 'Erreur micro: $e';
      notifyListeners();
    }
  }

  /// Arrête l'écoute et traite ce qui a été dicté
  Future<void> stopListening() async {
    if (_isListening) {
      await _speechToText.stop();
      _isListening = false;
      notifyListeners();

      if (_voiceTranscript.isNotEmpty) {
        await processCommand(_voiceTranscript);
      }
    }
  }

  /// Traite la commande vocale (ou saisie manuelle)
  Future<void> processCommand(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    _isProcessing = true;
    _voiceTranscript = trimmed;
    _speechError = null;
    notifyListeners();

    try {
      // 1. Si une action était en attente d'accord du pharmacien
      if (_pendingAction != null) {
        if (PharmacyVoiceNLPService.isAffirmative(trimmed)) {
          await confirmPendingAction();
          return;
        } else if (PharmacyVoiceNLPService.isNegative(trimmed)) {
          await cancelPendingAction();
          return;
        }
      }

      // 2. Analyse NLP de la commande
      final result = _nlpService.parseCommand(
        voiceInput: trimmed,
        currentStockItems: _stockItems,
        allCatalogMedicines: _allMedicines,
      );

      _lastResult = result;

      // 3. Si l'action modifie le stock/prix/emplacement : DEMANDER CONFIRMATION AVANT MODIFICATION
      if (result.requiresConfirmation && result.matchedItem != null) {
        final currentStock = result.matchedItem!.stock;
        final currentQty = currentStock.quantity;
        PharmacyStock? proposedStock;
        final confirmPrompt = result.confirmationPrompt ?? 'Voulez-vous valider cette action ?';
        final successSpeech = result.spokenResponse;

        switch (result.intent) {
          case VoiceIntentType.adjustStockDecrement:
            final change = result.quantity ?? 1;
            final newQty = (currentQty - change).clamp(0, 999999);
            proposedStock = currentStock.copyWith(
              quantity: newQty,
              inStock: newQty > 0,
              updatedAt: DateTime.now(),
            );
            break;

          case VoiceIntentType.adjustStockIncrement:
            final change = result.quantity ?? 1;
            final newQty = currentQty + change;
            proposedStock = currentStock.copyWith(
              quantity: newQty,
              inStock: newQty > 0,
              updatedAt: DateTime.now(),
            );
            break;

          case VoiceIntentType.setStockQuantity:
            final newQty = (result.quantity ?? 0).clamp(0, 999999);
            proposedStock = currentStock.copyWith(
              quantity: newQty,
              inStock: newQty > 0,
              updatedAt: DateTime.now(),
            );
            break;

          case VoiceIntentType.updatePrice:
            if (result.newPrice != null) {
              proposedStock = currentStock.copyWith(
                customPrice: result.newPrice!,
                updatedAt: DateTime.now(),
              );
            }
            break;

          case VoiceIntentType.updateLocation:
            if (result.newLocation != null) {
              proposedStock = currentStock.copyWith(
                shelfLocation: result.newLocation!,
                updatedAt: DateTime.now(),
              );
            }
            break;

          default:
            break;
        }

        if (proposedStock != null) {
          _pendingAction = PendingStockAction(
            parsedResult: result,
            currentStock: currentStock,
            updatedStock: proposedStock,
            confirmationQuestion: confirmPrompt,
            confirmationSpoken: confirmPrompt,
            successSpoken: successSpeech,
          );

          if (_isTtsEnabled) {
            await speak(confirmPrompt);
          }
          return;
        }
      }

      // 4. Pour les requêtes de consultation (stock, prix, emplacement, ruptures...)
      _pendingAction = null;
      if (_isTtsEnabled && result.spokenResponse.isNotEmpty) {
        await speak(result.spokenResponse);
      }
    } catch (e) {
      _speechError = 'Erreur lors du traitement : $e';
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  /// Confirme et applique définitivement l'action en attente
  Future<void> confirmPendingAction() async {
    if (_pendingAction == null) return;

    final action = _pendingAction!;
    _pendingAction = null;

    _undoStock = action.currentStock;
    await _stockRepository.update(action.updatedStock);
    await refreshStockData();

    if (_isTtsEnabled) {
      await speak(action.successSpoken);
    }
    notifyListeners();
  }

  /// Annule l'action en attente sans rien modifier
  Future<void> cancelPendingAction() async {
    if (_pendingAction == null) return;
    _pendingAction = null;

    const cancelMsg = 'Modification annulée.';
    if (_isTtsEnabled) {
      await speak(cancelMsg);
    }
    notifyListeners();
  }

  /// Annule la dernière action effectuée sur le stock (Undo)
  Future<void> undoLastAction() async {
    if (_undoStock == null) return;

    final targetStock = _undoStock!;
    _undoStock = null;

    await _stockRepository.update(targetStock);
    await refreshStockData();

    const undoMsg = 'Action annulée.';
    if (_isTtsEnabled) {
      await speak(undoMsg);
    }

    _lastResult = const VoiceParseResult(
      intent: VoiceIntentType.checkStock,
      rawQuery: 'Annulation',
      spokenResponse: undoMsg,
      actionDetails: 'État précédent rétabli',
    );
    notifyListeners();
  }

  /// Fait prononcer une phrase par l'assistant
  Future<void> speak(String text) async {
    if (!_isTtsEnabled || text.trim().isEmpty) return;
    try {
      await _flutterTts.speak(text);
    } catch (e) {
      debugPrint('[VoiceAssistant] TTS Speak error: $e');
    }
  }

  /// Coupe la voix en cours
  Future<void> stopSpeaking() async {
    try {
      await _flutterTts.stop();
      _isSpeaking = false;
      notifyListeners();
    } catch (_) {}
  }

  /// Active ou désactive le retour vocal
  void toggleTts() {
    _isTtsEnabled = !_isTtsEnabled;
    if (!_isTtsEnabled) {
      stopSpeaking();
    }
    notifyListeners();
  }

  @override
  void dispose() {
    stopSpeaking();
    if (_isListening) {
      _speechToText.stop();
    }
    super.dispose();
  }
}
