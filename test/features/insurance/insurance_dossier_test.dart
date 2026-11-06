import 'package:flutter_test/flutter_test.dart';
import 'package:medilink/features/insurance/data/insurance_dossier.dart';
import 'package:medilink/core/error/app_exception.dart';

void main() {
  test('French invoice suggestions use labelled totals and validate dates', () {
    final result = InvoiceSuggestions.fromText(
      'FACTURE 123\nDate : 10/01/2025\nTotal HT 90,000\nTVA 10,000\nTOTAL TTC : 100,000 TND',
    );
    expect(result.amount, 100);
    expect(result.date, DateTime(2025, 1, 10));
    expect(
      InvoiceSuggestions.fromText('Net à payer : 1 200,500 DT').amount,
      1200.5,
    );
    expect(InvoiceSuggestions.fromText('TOTAL : 1.200,500 DT').amount, 1200.5);
    expect(
      InvoiceSuggestions.fromText('Téléphone 12345678\n31/02/2025').amount,
      isNull,
    );
    expect(InvoiceSuggestions.fromText('31/02/2025').date, isNull);
    expect(InvoiceSuggestions.fromText('TOTAL TTC : 0,000').amount, isNull);
  });
  test(
    'simulations round to millimes; validity includes both date boundaries',
    () {
      expect(insuranceEstimate(10.005, .7), 7.004);
      final c = {
        'status': 'ACTIVE',
        'start_date': '2025-01-01',
        'end_date': '2025-12-31',
      };
      expect(contractIsUsable(c, DateTime(2025, 1, 1)), isTrue);
      expect(contractIsUsable(c, DateTime(2025, 12, 31)), isTrue);
      expect(contractIsUsable(c, DateTime(2026, 1, 1)), isFalse);
    },
  );
  test(
    'corrupt dossier fails explicitly rather than silently losing history',
    () {
      expect(
        () => InsuranceDossier.decode('${InsuranceDossier.prefix}{oops'),
        throwsA(isA<AppException>()),
      );
      expect(InsuranceDossier.decode(null).events, isEmpty);
    },
  );
}
