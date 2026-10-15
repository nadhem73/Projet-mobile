// Données fictives du module ai.
// À remplacer progressivement par les données SQLite (repositories du module).
import 'package:medilink/features/shell/data/models/inbox_model.dart';
import 'package:medilink/features/ai/data/models/lab_scan_model.dart';

List<MLInboxData> mlBotChatDataList() {
  List<MLInboxData> list = [];
  list.add(MLInboxData(
      id: 1,
      message: 'These are some of the frequantly asked question whencustomers use our services. Please '
          'choose the question you are intrested in'));
  list.add(MLInboxData(id: 0, message: 'yes'));
  list.add(MLInboxData(
      id: 1,
      message: 'Hi Kaixa, Thank you for using Medilink\'s consulting service.'
          'what are you intrested in our comprehensice checkup package?'));
  list.add(MLInboxData(id: 0, message: 'Get Started'));
  return list;
}

List<MLLabScanData> mlLabScanDataList() {
  List<MLLabScanData> list = [];
  list.add(MLLabScanData(title: 'Bilan sanguin complet', date: '21 Sep 2026', status: 'Analis�'));
  list.add(MLLabScanData(title: 'Glyc�mie � jeun', date: '14 Sep 2026', status: 'Analis�'));
  list.add(MLLabScanData(title: 'Bilan lipidique', date: '02 Sep 2026', status: 'En attente'));
  list.add(MLLabScanData(title: 'NFS - Num�ration formule', date: '25 Aug 2026', status: 'Analis�'));
  return list;
}
