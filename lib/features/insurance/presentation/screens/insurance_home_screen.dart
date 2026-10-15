import 'package:flutter/material.dart';
import 'package:medilink/core/widgets/widgets.dart';

/// Point d'entrée du module Assurance (à développer par le Membre 3).
class InsuranceHomeScreen extends StatelessWidget {
  const InsuranceHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Assurance')),
      body: const ComingSoonView(
        title: 'Module Assurance',
        message: 'Contrats, prise en charge et suivi des remboursements arrivent bientôt.',
      ),
    );
  }
}
