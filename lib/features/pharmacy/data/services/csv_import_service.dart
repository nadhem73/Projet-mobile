import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:medilink/features/pharmacy/data/models/medicine.dart';
import 'package:medilink/features/pharmacy/data/models/pharmacy_stock.dart';

/// Service pour importer des médicaments et stocks depuis fichiers CSV.
///
/// Gère le parsing de CSV avec encodage UTF-8 (caractères français: é, è, à).
/// Supporte l'import par batch pour les grandes quantités de données.
class CsvImportService {
  /// Délimiteur utilisé dans les fichiers CSV.
  static const String delimiter = ';';

  /// Parse un fichier CSV de médicaments depuis les assets.
  ///
  /// Format attendu: Name;Dosage;Forme;Presentation;Price;Remboursement;DCI;Type;Prescription;Image
  ///
  /// [assetPath]: Chemin du fichier CSV dans assets (e.g., 'medicine_data_tn_with_images.csv')
  /// [onProgress]: Callback optionnel pour suivre la progression (current, total)
  ///
  /// Returns: Liste de [Medicine] parsés depuis le CSV
  Future<List<Medicine>> parseMedicinesCsvFromAsset(
    String assetPath, {
    void Function(int current, int total)? onProgress,
  }) async {
    final csvContent = await rootBundle.loadString(assetPath);
    return _parseMedicinesCsv(csvContent, onProgress: onProgress);
  }

  /// Parse un contenu CSV de médicaments.
  List<Medicine> _parseMedicinesCsv(
    String csvContent, {
    void Function(int current, int total)? onProgress,
  }) {
    final lines = const LineSplitter().convert(csvContent);
    if (lines.isEmpty) return [];

    // Skip header line
    final dataLines = lines.skip(1).toList();
    final medicines = <Medicine>[];

    for (var i = 0; i < dataLines.length; i++) {
      final line = dataLines[i].trim();
      if (line.isEmpty) continue;

      try {
        final fields = _splitCsvLine(line);
        if (fields.isEmpty || fields[0].isEmpty) continue;

        final medicine = Medicine.fromCsv(fields);
        medicines.add(medicine);

        // Progress callback
        if (onProgress != null && (i + 1) % 100 == 0) {
          onProgress(i + 1, dataLines.length);
        }
      } catch (e) {
        // Skip invalid lines and continue
        debugPrint('Warning: Could not parse medicine line ${i + 1}: $e');
        continue;
      }
    }

    // Final progress update
    onProgress?.call(medicines.length, dataLines.length);

    return medicines;
  }

  /// Parse un fichier CSV de stock depuis les assets.
  ///
  /// Format attendu: id_medicament;quantite_en_stock;date_fabrication;date_expiration;emplacement;dernier_reapprovisionnement
  ///
  /// [assetPath]: Chemin du fichier CSV dans assets (e.g., 'stock_medicaments_tn.csv')
  /// [pharmacyId]: ID de la pharmacie propriétaire du stock
  /// [onProgress]: Callback optionnel pour suivre la progression
  ///
  /// Returns: Liste de [PharmacyStock] parsés depuis le CSV
  Future<List<PharmacyStock>> parseStockCsvFromAsset(
    String assetPath,
    int pharmacyId, {
    void Function(int current, int total)? onProgress,
  }) async {
    final csvContent = await rootBundle.loadString(assetPath);
    return _parseStockCsv(csvContent, pharmacyId, onProgress: onProgress);
  }

  /// Parse un contenu CSV de stock.
  List<PharmacyStock> _parseStockCsv(
    String csvContent,
    int pharmacyId, {
    void Function(int current, int total)? onProgress,
  }) {
    final lines = const LineSplitter().convert(csvContent);
    if (lines.isEmpty) return [];

    // Skip header line
    final dataLines = lines.skip(1).toList();
    final stockItems = <PharmacyStock>[];

    for (var i = 0; i < dataLines.length; i++) {
      final line = dataLines[i].trim();
      if (line.isEmpty) continue;

      try {
        final fields = _splitCsvLine(line);
        if (fields.isEmpty) continue;

        final stock = PharmacyStock.fromCsv(fields, pharmacyId);
        stockItems.add(stock);

        // Progress callback
        if (onProgress != null && (i + 1) % 100 == 0) {
          onProgress(i + 1, dataLines.length);
        }
      } catch (e) {
        // Skip invalid lines and continue
        debugPrint('Warning: Could not parse stock line ${i + 1}: $e');
        continue;
      }
    }

    // Final progress update
    onProgress?.call(stockItems.length, dataLines.length);

    return stockItems;
  }

  /// Split une ligne CSV en respectant le délimiteur.
  ///
  /// Gère les champs entre guillemets si nécessaire.
  List<String> _splitCsvLine(String line) {
    return line.split(delimiter);
  }

  /// Parse un fichier CSV personnalisé avec un délimiteur spécifique.
  ///
  /// Utile pour des imports CSV génériques.
  Future<List<List<String>>> parseGenericCsv(
    String csvContent, {
    String delimiter = ';',
    bool skipHeader = true,
  }) async {
    final lines = const LineSplitter().convert(csvContent);
    if (lines.isEmpty) return [];

    final dataLines = skipHeader ? lines.skip(1) : lines;
    final result = <List<String>>[];

    for (final line in dataLines) {
      if (line.trim().isEmpty) continue;
      final fields = line.split(delimiter).map((f) => f.trim()).toList();
      result.add(fields);
    }

    return result;
  }

  /// Valide le format d'un fichier CSV de médicaments.
  ///
  /// Vérifie que le header correspond au format attendu.
  Future<bool> validateMedicineCsvFormat(String assetPath) async {
    try {
      final csvContent = await rootBundle.loadString(assetPath);
      final lines = const LineSplitter().convert(csvContent);
      if (lines.isEmpty) return false;

      final header = lines.first.toLowerCase();
      // Check for required fields
      return header.contains('name') &&
          header.contains('price') &&
          (header.contains('dci') || header.contains('dosage'));
    } catch (e) {
      return false;
    }
  }

  /// Valide le format d'un fichier CSV de stock.
  Future<bool> validateStockCsvFormat(String assetPath) async {
    try {
      final csvContent = await rootBundle.loadString(assetPath);
      final lines = const LineSplitter().convert(csvContent);
      if (lines.isEmpty) return false;

      final header = lines.first.toLowerCase();
      // Check for required fields
      return header.contains('id_medicament') && header.contains('quantite');
    } catch (e) {
      return false;
    }
  }
}
