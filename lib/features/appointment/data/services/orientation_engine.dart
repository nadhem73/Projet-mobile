import 'package:medilink/features/appointment/data/models/orientation_result.dart';
import 'package:medilink/features/appointment/data/services/llm_orientation_service.dart';
import 'package:medilink/features/appointment/data/services/symptom_analyzer.dart';

/// Choisit la meilleure analyse disponible : LLM en ligne, sinon mots-clés hors ligne.
///
/// Règles de sécurité :
/// 1. Si l'analyse hors ligne repère une urgence, on la garde sans attendre le LLM.
/// 2. Si le LLM est désactivé, injoignable ou répond n'importe quoi, on garde l'analyse hors ligne.
/// 3. Si le LLM voit une urgence que les mots-clés n'ont pas repérée, on garde l'urgence.
class OrientationEngine {
  const OrientationEngine(this._offline, this._llm);

  final SymptomAnalyzer _offline;
  final LlmOrientationService? _llm;

  bool get usesLlm => _llm?.isEnabled ?? false;

  Future<OrientationResult> analyze(String symptoms) async {
    final offline = _offline.analyze(symptoms);
    if (offline.isEmergency || !usesLlm) return offline;

    final online = await _llm!.analyze(symptoms);
    return online ?? offline;
  }
}
