import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:medilink/core/error/app_exception.dart';
import 'package:medilink/core/session/session_service.dart';
import 'package:medilink/features/ai/ai_config.dart';
import 'package:medilink/features/ai/data/ocr/bilan_parser.dart';
import 'package:medilink/features/ai/data/ocr/image_preprocessor.dart';
import 'package:medilink/features/ai/data/ocr/ocr_engine.dart';
import 'package:medilink/features/ai/data/repositories/bilan_api.dart';
import 'package:medilink/features/ai/data/repositories/bilan_image_store.dart';
import 'package:medilink/features/ai/data/repositories/bilan_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Étapes affichées pendant l'analyse.
enum ScanStep {
  idle(''),
  uploading('Envoi au serveur…'),
  preprocessing('Amélioration de l\'image…'),
  recognizing('Lecture du texte (OCR)…'),
  parsing('Extraction des valeurs…'),
  done('Analyse terminée'),
  error('');

  const ScanStep(this.label);

  final String label;

  bool get isBusy => this != idle && this != done && this != error;
}

/// Écran « Scanner un bilan » : photo → recadrage → analyse (serveur si
/// configuré et joignable, sinon OCR Tesseract local) → enregistrement.
class BilanScanController extends ChangeNotifier {
  BilanScanController(
    this._repository,
    this._api,
    this._parser,
    this._ocr,
    this._preprocessor,
    this._images,
    this._session,
    this._prefs, {
    ImagePicker? picker,
    ImageCropper? cropper,
    Connectivity? connectivity,
  }) : _picker = picker ?? ImagePicker(),
       _cropper = cropper ?? ImageCropper(),
       _connectivity = connectivity ?? Connectivity();

  final BilanRepository _repository;
  final BilanApi _api;
  final BilanParser _parser;
  final OcrEngine _ocr;
  final ImagePreprocessor _preprocessor;
  final BilanImageStore _images;
  final SessionService _session;
  final SharedPreferences _prefs;
  final ImagePicker _picker;
  final ImageCropper _cropper;
  final Connectivity _connectivity;

  ScanStep step = ScanStep.idle;

  /// Progression de l'envoi (0..1), `null` = indéterminée.
  double? progress;
  String? error;

  /// Bilan créé, à ouvrir dans l'écran de revue.
  String? bilanId;

  /// `true` si le dernier bilan a été analysé sur le téléphone.
  bool analysedOffline = false;

  String? _lastImage;

  bool get canRetry => _lastImage != null && step == ScanStep.error;
  bool get serverConfigured => _api.isEnabled;
  bool get offlineForced => _prefs.getBool(AiConfig.offlineOcrKey) ?? false;

  Future<void> setOfflineForced(bool value) async {
    await _prefs.setBool(AiConfig.offlineOcrKey, value);
    notifyListeners();
  }

  /// Caméra ou galerie, puis recadrage et compression (JPEG 85, ≤ 2000 px).
  Future<void> pick(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(source: source, maxWidth: 2000, imageQuality: 85);
      if (picked == null) return;
      final cropped = await _cropper.cropImage(
        sourcePath: picked.path,
        compressFormat: ImageCompressFormat.jpg,
        compressQuality: 85,
        maxWidth: 2000,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Recadrer le bilan',
            lockAspectRatio: false,
            initAspectRatio: CropAspectRatioPreset.original,
            hideBottomControls: false,
          ),
          IOSUiSettings(title: 'Recadrer le bilan', doneButtonTitle: 'Valider', cancelButtonTitle: 'Annuler'),
        ],
      );
      _lastImage = await _images.keep(cropped?.path ?? picked.path);
      await _analyse(_lastImage!);
    } catch (e) {
      _fail(e is AppException ? e.message : 'Impossible d\'ouvrir l\'image : vérifiez les autorisations.');
    }
  }

  Future<void> retry() async {
    final image = _lastImage;
    if (image != null) await _analyse(image);
  }

  /// Revient à l'écran d'accueil du scan après ouverture du bilan.
  void reset() {
    step = ScanStep.idle;
    bilanId = null;
    error = null;
    progress = null;
    notifyListeners();
  }

  Future<void> _analyse(String imagePath) async {
    final patientId = _session.requireUser.patientId;
    if (patientId == null) return _fail('Seul un patient peut scanner un bilan.');
    error = null;
    bilanId = null;

    try {
      if (!offlineForced && _api.isEnabled && await _isOnline()) {
        try {
          _set(ScanStep.uploading, progress: 0);
          final server = await _api.scan(imagePath, onProgress: (p) => _set(ScanStep.uploading, progress: p));
          final saved = await _repository.save(
            server.copyWith(patientId: patientId, synced: true, imagePath: imagePath),
          );
          analysedOffline = false;
          bilanId = saved.id;
          return _set(ScanStep.done);
        } on AppException catch (e) {
          // Réseau coupé ou serveur trop lent : on bascule sur l'OCR local.
          if (e.code != 'offline' && e.code != 'timeout' && e.code != 'server') rethrow;
          debugPrint('[BilanScan] serveur indisponible (${e.code}) → OCR local');
        }
      }

      _set(ScanStep.preprocessing);
      final prepared = await _preprocessor.process(imagePath);
      _set(ScanStep.recognizing);
      final text = await _ocr.recognize(prepared);
      if (text.trim().length < OcrEngine.minUsefulLength) {
        return _fail('Aucun texte lisible. Reprenez la photo bien à plat, avec plus de lumière.');
      }
      _set(ScanStep.parsing);
      final bilan = _parser
          .parse(text, id: BilanRepository.newLocalId(), patientId: patientId)
          .copyWith(imagePath: imagePath);
      if (bilan.resultats.isEmpty) {
        return _fail('Aucune valeur de bilan reconnue. Cadrez uniquement le tableau des résultats.');
      }
      final saved = await _repository.save(bilan, rawText: text);
      analysedOffline = true;
      bilanId = saved.id;
      _set(ScanStep.done);
    } on AppException catch (e) {
      _fail(e.message);
    } catch (e) {
      debugPrint('[BilanScan] $e');
      _fail('L\'analyse a échoué. Réessayez avec une photo plus nette.');
    }
  }

  Future<bool> _isOnline() async {
    final results = await _connectivity.checkConnectivity();
    return results.any((r) => r != ConnectivityResult.none);
  }

  void _set(ScanStep value, {double? progress}) {
    step = value;
    this.progress = progress;
    notifyListeners();
  }

  void _fail(String message) {
    error = message;
    _set(ScanStep.error);
  }
}
