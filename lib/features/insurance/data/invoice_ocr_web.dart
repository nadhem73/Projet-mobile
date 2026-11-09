import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_tesseract_ocr/flutter_tesseract_ocr.dart';

Future<String> recognizeInvoice(Uint8List bytes) =>
    FlutterTesseractOcr.extractText(
      'data:image/${bytes.first == 137
          ? 'png'
          : bytes.first == 82
          ? 'webp'
          : 'jpeg'};base64,${base64Encode(bytes)}',
      language: 'fra',
      args: {'preserve_interword_spaces': '1'},
    );
