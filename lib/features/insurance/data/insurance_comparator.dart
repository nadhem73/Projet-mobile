/// A self-contained teaching catalogue. These are not real offers or insurers.
class DemoInsuranceOffer {
  const DemoInsuranceOffer(this.id, this.name, this.monthlyCost, this.benefits);
  final String id;
  final String name;
  final double monthlyCost;
  final Set<String> benefits;
}

const demoBenefits = <String, String>{
  'consultations': 'Consultations',
  'pharmacy': 'Pharmacie',
  'hospital': 'Hospitalisation',
  'dental': 'Dentaire',
};

const demoInsuranceOffers = <DemoInsuranceOffer>[
  DemoInsuranceOffer('demo_essential', 'Essentielle', 25, {
    'consultations',
    'pharmacy',
  }),
  DemoInsuranceOffer('demo_balance', 'Équilibre', 45, {
    'consultations',
    'pharmacy',
    'hospital',
  }),
  DemoInsuranceOffer('demo_complete', 'Complète', 65, {
    'consultations',
    'pharmacy',
    'hospital',
    'dental',
  }),
];

class DemoOfferScore {
  const DemoOfferScore(this.offer, this.matches, this.score);
  final DemoInsuranceOffer offer;
  final int matches;
  final double score;
}

/// Filter on budget, then score declared priorities (70%) and cost (30%).
/// This is a teaching heuristic, not financial advice or eligibility verification.
List<DemoOfferScore> rankDemoOffers(double budget, Set<String> priorities) {
  if (!budget.isFinite ||
      budget <= 0 ||
      budget > 10000 ||
      priorities.isEmpty ||
      !demoBenefits.keys.toSet().containsAll(priorities)) {
    return [];
  }
  final ranked = <DemoOfferScore>[];
  for (final offer in demoInsuranceOffers) {
    if (offer.monthlyCost > budget) continue;
    final matches = offer.benefits.intersection(priorities).length;
    final score =
        70 * matches / priorities.length +
        30 * (budget - offer.monthlyCost) / budget;
    ranked.add(DemoOfferScore(offer, matches, score));
  }
  ranked.sort((a, b) {
    final byScore = b.score.compareTo(a.score);
    return byScore != 0
        ? byScore
        : a.offer.monthlyCost.compareTo(b.offer.monthlyCost);
  });
  return ranked;
}
