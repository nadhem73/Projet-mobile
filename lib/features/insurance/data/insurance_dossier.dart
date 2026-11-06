import 'dart:convert';
import 'dart:typed_data';

import 'package:medilink/core/error/app_exception.dart';

/// Versioned local dossier stored in the existing document_path TEXT column.
/// Older plain paths remain readable and are preserved when adding history.
class InsuranceDossier {
  InsuranceDossier({
    this.careDate,
    this.requestedDocuments,
    this.legacyPath,
    List<InsuranceAttachment>? attachments,
    List<Map<String, dynamic>>? events,
  }) : attachments = attachments ?? [],
       events = events ?? [];

  static const prefix = 'medilink-dossier:v1:';
  String? careDate;
  String? requestedDocuments;
  String? legacyPath;
  final List<InsuranceAttachment> attachments;
  final List<Map<String, dynamic>> events;

  factory InsuranceDossier.decode(Object? value) {
    if (value == null || value == '') return InsuranceDossier();
    final raw = value as String;
    if (!raw.startsWith(prefix)) return InsuranceDossier(legacyPath: raw);
    try {
      final json =
          jsonDecode(raw.substring(prefix.length)) as Map<String, dynamic>;
      return InsuranceDossier(
        careDate: json['careDate'] as String?,
        requestedDocuments: json['requestedDocuments'] as String?,
        legacyPath: json['legacyPath'] as String?,
        attachments:
            (json['attachments'] as List)
                .map((e) => InsuranceAttachment.fromJson(e))
                .toList(),
        events:
            (json['events'] as List)
                .map((e) => Map<String, dynamic>.from(e))
                .toList(),
      );
    } catch (_) {
      // Never silently overwrite an unsupported/corrupt dossier on a mutation.
      throw const AppException(
        'Ce dossier ne peut pas être lu. Ses données ont été conservées.',
      );
    }
  }

  void record(String action, String actor, {String? note, double? amount}) {
    events.add({
      'action': action,
      'actor': actor,
      'at': DateTime.now().toUtc().toIso8601String(),
      if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
      if (amount != null) 'amount': amount,
    });
  }

  String encode() =>
      prefix +
      jsonEncode({
        'careDate': careDate,
        'requestedDocuments': requestedDocuments,
        'legacyPath': legacyPath,
        'attachments': attachments.map((a) => a.toJson()).toList(),
        'events': events,
      });
}

class InsuranceAttachment {
  const InsuranceAttachment({required this.name, required this.bytes});
  final String name;
  final Uint8List bytes;
  static const maxBytes = 3 * 1024 * 1024;

  factory InsuranceAttachment.fromJson(dynamic json) => InsuranceAttachment(
    name: json['name'] as String,
    bytes: base64Decode(json['data'] as String),
  );
  Map<String, Object> toJson() => {'name': name, 'data': base64Encode(bytes)};

  void validate() {
    final png =
        bytes.length > 8 &&
        bytes[0] == 137 &&
        bytes[1] == 80 &&
        bytes[2] == 78 &&
        bytes[3] == 71;
    final jpeg =
        bytes.length > 3 &&
        bytes[0] == 255 &&
        bytes[1] == 216 &&
        bytes[2] == 255;
    final webp =
        bytes.length > 12 &&
        ascii.decode(bytes.sublist(0, 4), allowInvalid: true) == 'RIFF' &&
        ascii.decode(bytes.sublist(8, 12), allowInvalid: true) == 'WEBP';
    if (name.trim().isEmpty ||
        name.length > 160 ||
        bytes.length > maxBytes ||
        !(png || jpeg || webp)) {
      throw const AppException(
        'Choisissez une image JPEG, PNG ou WebP de 3 Mo maximum.',
      );
    }
  }
}

bool contractIsUsable(Map<String, Object?> contract, [DateTime? at]) {
  final now = at ?? DateTime.now();
  final day = DateTime(now.year, now.month, now.day);
  final start = DateTime.tryParse('${contract['start_date']}');
  final end = DateTime.tryParse('${contract['end_date']}');
  return contract['status'] == 'ACTIVE' &&
      (start == null || !day.isBefore(start)) &&
      (end == null || !day.isAfter(end));
}

double insuranceEstimate(num amount, num rate) =>
    (amount * rate * 1000).round() / 1000;

/// Conservative suggestions: only a labelled TOTAL/TTC and a valid calendar date.
/// Nothing is submitted until the patient reviews the form.
class InvoiceSuggestions {
  const InvoiceSuggestions({this.amount, this.date});
  final double? amount;
  final DateTime? date;

  factory InvoiceSuggestions.fromText(String text) {
    double? amount;
    final total = RegExp(
      r'(?:total\s*(?:ttc|[àa]\s*payer)?|net\s*[àa]\s*payer|montant\s*ttc)\s*[:=]?\s*(\d[\d .\u00a0]*[,.]\d{2,3}|\d+)(?:\s*(?:TND|DT|DINARS))?',
      caseSensitive: false,
    );
    for (final match in total.allMatches(text)) {
      final raw = match.group(1)!.replaceAll(RegExp(r'[\s\u00a0]'), '');
      final normalized =
          raw.contains(',')
              ? raw.replaceAll('.', '').replaceAll(',', '.')
              : raw;
      final n = double.tryParse(normalized);
      if (n != null && n > 0 && n <= 10000000) amount = n;
    }
    DateTime? date;
    final match = RegExp(r'\b(\d{2})[/-](\d{2})[/-](\d{4})\b').firstMatch(text);
    if (match != null) {
      final d = int.parse(match[1]!);
      final m = int.parse(match[2]!);
      final y = int.parse(match[3]!);
      final candidate = DateTime(y, m, d);
      if (candidate.day == d &&
          candidate.month == m &&
          y >= 1900 &&
          !candidate.isAfter(DateTime.now())) {
        date = candidate;
      }
    }
    return InvoiceSuggestions(amount: amount, date: date);
  }
}
