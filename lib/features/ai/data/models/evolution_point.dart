/// Une mesure d'un test dans un bilan confirmé (écran Évolution).
class EvolutionPoint {
  const EvolutionPoint({required this.date, required this.value, this.min, this.max, required this.unit});

  final DateTime date;
  final double value;
  final double? min;
  final double? max;
  final String unit;
}
