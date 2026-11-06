import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// Prépare une photo de bilan pour Tesseract : niveaux de gris,
/// auto-contraste, agrandissement ×2 si largeur < 1500 px, filtre médian 3×3.
///
/// Le traitement tourne dans un isolate pour ne pas figer l'interface.
class ImagePreprocessor {
  const ImagePreprocessor();

  static const int minWidth = 1500;

  /// Écrit l'image traitée à côté de l'originale et renvoie son chemin.
  Future<String> process(String path) => Isolate.run(() => processSync(path));

  static String processSync(String path) {
    final decoded = img.decodeImage(File(path).readAsBytesSync());
    if (decoded == null) throw const FormatException('Image illisible');
    final bytes = processImage(decoded);
    final out = path.replaceFirst(RegExp(r'(\.\w+)?$'), '_ocr.jpg');
    File(out).writeAsBytesSync(bytes);
    return out;
  }

  /// Traitement pur (testable sans fichier) → JPEG.
  static Uint8List processImage(img.Image source) {
    var image = img.bakeOrientation(source).convert(format: img.Format.uint8, numChannels: 3);
    if (image.width < minWidth) {
      image = img.copyResize(image, width: image.width * 2, interpolation: img.Interpolation.cubic);
    }
    final w = image.width, h = image.height;

    // ---- Niveaux de gris ----
    final rgb = image.getBytes(order: img.ChannelOrder.rgb);
    final gray = Uint8List(w * h);
    for (var i = 0, j = 0; i < gray.length; i++, j += 3) {
      gray[i] = (rgb[j] * 299 + rgb[j + 1] * 587 + rgb[j + 2] * 114) ~/ 1000;
    }

    // ---- Auto-contraste (étirement entre les percentiles 1 % et 99 %) ----
    _autoContrast(gray);

    // ---- Filtre médian 3×3 (supprime le bruit « poivre et sel ») ----
    final filtered = _median3x3(gray, w, h);

    final out = Uint8List(w * h * 3);
    for (var i = 0, j = 0; i < filtered.length; i++, j += 3) {
      out[j] = out[j + 1] = out[j + 2] = filtered[i];
    }
    final result = img.Image.fromBytes(width: w, height: h, bytes: out.buffer, numChannels: 3);
    return img.encodeJpg(result, quality: 90);
  }

  static void _autoContrast(Uint8List gray) {
    final histogram = List<int>.filled(256, 0);
    for (final v in gray) {
      histogram[v]++;
    }
    final cut = gray.length ~/ 100;
    var low = 0, high = 255, acc = 0;
    while (low < 255 && (acc += histogram[low]) <= cut) {
      low++;
    }
    acc = 0;
    while (high > 0 && (acc += histogram[high]) <= cut) {
      high--;
    }
    if (high - low < 10) return; // image uniforme : rien à étirer
    final scale = 255 / (high - low);
    final lut = Uint8List.fromList([for (var v = 0; v < 256; v++) ((v - low) * scale).round().clamp(0, 255)]);
    for (var i = 0; i < gray.length; i++) {
      gray[i] = lut[gray[i]];
    }
  }

  static Uint8List _median3x3(Uint8List src, int w, int h) {
    final dst = Uint8List.fromList(src); // les bords sont conservés
    final window = List<int>.filled(9, 0);
    for (var y = 1; y < h - 1; y++) {
      for (var x = 1; x < w - 1; x++) {
        var k = 0;
        for (var dy = -1; dy <= 1; dy++) {
          final row = (y + dy) * w + x;
          window[k++] = src[row - 1];
          window[k++] = src[row];
          window[k++] = src[row + 1];
        }
        // Tri par insertion de 9 valeurs : plus rapide qu'un sort() générique.
        for (var i = 1; i < 9; i++) {
          final v = window[i];
          var j = i - 1;
          while (j >= 0 && window[j] > v) {
            window[j + 1] = window[j];
            j--;
          }
          window[j + 1] = v;
        }
        dst[y * w + x] = window[4];
      }
    }
    return dst;
  }
}
