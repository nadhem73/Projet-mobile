import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:medilink/features/ai/data/ocr/ocr_engine.dart';
import 'package:medilink/features/user/data/ai/document_classifier.dart';
import 'package:path_provider/path_provider.dart';

/// Lit une photo de document (OCR sur le téléphone) puis propose une
/// catégorie et un titre.
///
/// Réutilise le moteur OCR du module IA (Tesseract `fra` + ML Kit).
/// Sur le Web, l'OCR natif n'existe pas : [suggest] renvoie null et
/// l'utilisateur saisit les détails lui-même.
class DocumentAnalyzer {
  DocumentAnalyzer(this._ocr, this._classifier, {Future<Directory> Function()? tempDir})
    : _tempDir = tempDir ?? getTemporaryDirectory;

  final OcrEngine _ocr;
  final DocumentClassifier _classifier;
  final Future<Directory> Function() _tempDir;

  bool get isAvailable => !kIsWeb;

  Future<DocumentSuggestion?> suggest(Uint8List imageBytes) async {
    if (!isAvailable) return null;
    File? file;
    try {
      final dir = await _tempDir();
      file = File('${dir.path}/doc_ocr_${DateTime.now().microsecondsSinceEpoch}.jpg');
      await file.writeAsBytes(imageBytes, flush: true);
      final text = await _ocr.recognize(file.path);
      return _classifier.classify(text);
    } catch (e) {
      debugPrint('[DocumentAnalyzer] $e');
      return null;
    } finally {
      // L'image est déjà stockée dans la base : la copie temporaire est supprimée.
      try {
        await file?.delete();
      } catch (_) {}
    }
  }
}
