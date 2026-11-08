import 'package:flutter/foundation.dart';
import 'package:flutter_tesseract_ocr/flutter_tesseract_ocr.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// Reconnaissance de texte sur le téléphone (mode hors-ligne).
///
/// 1. Tesseract `fra` en PSM 4 (colonne de texte de tailles variables : le
///    format des bilans) ;
/// 2. Tesseract PSM 3 (segmentation automatique) si le résultat est trop court ;
/// 3. Google ML Kit (latin) en dernier recours.
class OcrEngine {
  const OcrEngine();

  /// En dessous, on considère que l'OCR a échoué.
  static const int minUsefulLength = 20;

  Future<String> recognize(String imagePath) async {
    var best = '';
    for (final psm in const ['4', '3']) {
      try {
        final text = await FlutterTesseractOcr.extractText(
          imagePath,
          language: 'fra',
          args: {'psm': psm, 'preserve_interword_spaces': '1'},
        );
        if (text.trim().length >= minUsefulLength) return text;
        if (text.length > best.length) best = text;
      } catch (e) {
        debugPrint('[OcrEngine] Tesseract PSM $psm : $e');
      }
    }

    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final result = await recognizer.processImage(InputImage.fromFilePath(imagePath));
      if (result.text.trim().length > best.trim().length) best = result.text;
    } catch (e) {
      debugPrint('[OcrEngine] ML Kit : $e');
    } finally {
      await recognizer.close();
    }
    return best;
  }
}
