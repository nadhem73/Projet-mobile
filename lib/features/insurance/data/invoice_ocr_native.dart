import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_tesseract_ocr/flutter_tesseract_ocr.dart';
import 'package:path_provider/path_provider.dart';

Future<String> recognizeInvoice(Uint8List bytes) async {
  if (!Platform.isAndroid && !Platform.isIOS) {
    throw UnsupportedError('OCR disponible sur Android, iOS et navigateur.');
  }
  final dir = await Directory(
    (await getTemporaryDirectory()).path,
  ).createTemp('invoice_');
  final image = File(
    '${dir.path}/invoice.${bytes.first == 137
        ? 'png'
        : bytes.first == 82
        ? 'webp'
        : 'jpg'}',
  );
  try {
    await image.writeAsBytes(bytes, flush: true);
    return await FlutterTesseractOcr.extractText(
      image.path,
      language: 'fra',
      args: {'preserve_interword_spaces': '1'},
    );
  } finally {
    await dir.delete(recursive: true);
  }
}
