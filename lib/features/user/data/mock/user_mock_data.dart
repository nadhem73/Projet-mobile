// Données fictives du module user (écran hérité « ajouter une personne à charge »).
// À remplacer par les données SQLite quand la gestion des proches sera développée.
import 'package:medilink/features/user/data/models/patient_model.dart';

List<MLPatientData> mlPatientDataList() {
  List<MLPatientData> list = [];
  list.add(MLPatientData(name: 'Kaixa Pham', dob: '21-09-1995', relation: 'label'));
  list.add(MLPatientData(name: 'Stephen Chew', dob: '12-11-1990', relation: 'Brother'));
  return list;
}
