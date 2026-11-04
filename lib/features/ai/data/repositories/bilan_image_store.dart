import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Conserve les photos de bilans dans le dossier de l'application (le cache
/// d'image_picker peut être vidé par le système) pour pouvoir les renvoyer
/// au serveur au retour du réseau.
class BilanImageStore {
  const BilanImageStore();

  Future<String> keep(String sourcePath) async {
    final dir = Directory(p.join((await getApplicationDocumentsDirectory()).path, 'bilans'));
    await dir.create(recursive: true);
    final target = p.join(dir.path, 'bilan_${DateTime.now().millisecondsSinceEpoch}.jpg');
    return (await File(sourcePath).copy(target)).path;
  }

  Future<void> remove(String? path) async {
    if (path == null) return;
    final file = File(path);
    if (await file.exists()) await file.delete();
  }
}
