import 'dart:typed_data';
import 'invoice_ocr_stub.dart'
    if (dart.library.io) 'invoice_ocr_native.dart'
    if (dart.library.js_interop) 'invoice_ocr_web.dart'
    as platform;

/// Runs on-device. No invoice is sent to a remote recognition service.
Future<String> recognizeInvoice(Uint8List bytes) =>
    platform.recognizeInvoice(bytes);
