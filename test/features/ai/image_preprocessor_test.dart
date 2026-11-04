import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:medilink/features/ai/data/ocr/image_preprocessor.dart';

void main() {
  img.Image sample(int width, int height) {
    final image = img.Image(width: width, height: height);
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        // Fond gris clair peu contrasté + « texte » gris foncé + un pixel de bruit blanc.
        final isText = y > height ~/ 3 && y < height ~/ 2 && x % 7 < 3;
        final v = isText ? 110 : 150;
        image.setPixelRgb(x, y, v + 10, v, v - 10);
      }
    }
    image.setPixelRgb(width ~/ 2, height - 5, 255, 255, 255);
    return image;
  }

  test('petite image : agrandie ×2, niveaux de gris, contraste étiré', () {
    final out = img.decodeJpg(ImagePreprocessor.processImage(sample(300, 200)))!;
    expect(out.width, 600);
    expect(out.height, 400);

    var minLum = 255, maxLum = 0;
    for (final p in out) {
      expect((p.r - p.g).abs(), lessThanOrEqualTo(3), reason: 'image en niveaux de gris');
      minLum = p.r.toInt() < minLum ? p.r.toInt() : minLum;
      maxLum = p.r.toInt() > maxLum ? p.r.toInt() : maxLum;
    }
    // Écart d'origine ≈ 40 niveaux : l'auto-contraste l'étire presque à 0..255.
    expect(maxLum - minLum, greaterThan(200));
  });

  test('le filtre médian supprime un pixel de bruit isolé', () {
    final source = sample(1600, 100)..setPixelRgb(800, 90, 0, 0, 0); // point noir sur le fond clair
    final out = img.decodeJpg(ImagePreprocessor.processImage(source))!;
    expect(out.getPixel(800, 90).r, greaterThan(200));
  });

  test('image déjà large : pas d\'agrandissement', () {
    final out = img.decodeJpg(ImagePreprocessor.processImage(sample(1600, 100)))!;
    expect(out.width, 1600);
  });
}
