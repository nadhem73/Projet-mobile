// Copie la base SQLite de l'application (émulateur / téléphone Android) dans
// `medilink.db` à la racine du projet, pour l'ouvrir avec SQLite Viewer ou
// DB Browser.
//
//   dart run tool/sync_db.dart           # une copie
//   dart run tool/sync_db.dart --watch   # recopie dès que la base change (Ctrl+C pour arrêter)
//
// L'application doit être une version debug installée sur l'appareil
// (`flutter run`), sinon `run-as` est refusé.
import 'dart:io';

const _package = 'tn.medilink.app';
const _remote = 'databases/medilink.db';
const _target = 'medilink.db';

Future<void> main(List<String> args) async {
  final adb = _findAdb();
  final watch = args.contains('--watch');

  if (!watch) {
    exit(await _pull(adb) ? 0 : 1);
  }

  stdout.writeln('Synchronisation continue de $_target (Ctrl+C pour arrêter)...');
  String? lastStamp;
  while (true) {
    final stamp = await _remoteStamp(adb);
    if (stamp != null && stamp != lastStamp && await _pull(adb)) lastStamp = stamp;
    await Future<void>.delayed(const Duration(seconds: 2));
  }
}

/// Taille + date de modification de la base sur l'appareil (null si inaccessible).
Future<String?> _remoteStamp(String adb) async {
  final result = await Process.run(adb, ['shell', 'run-as', _package, 'stat', '-c', '%s %Y', _remote]);
  return result.exitCode == 0 ? (result.stdout as String).trim() : null;
}

Future<bool> _pull(String adb) async {
  final result = await Process.run(adb, [
    'exec-out',
    'run-as',
    _package,
    'cat',
    _remote,
  ], stdoutEncoding: null);
  final bytes = result.stdout as List<int>;
  // Un fichier SQLite commence par « SQLite format 3 ».
  if (result.exitCode != 0 || bytes.length < 100 || String.fromCharCodes(bytes.take(15)) != 'SQLite format 3') {
    stderr.writeln(
      'Impossible de lire la base sur l\'appareil. Vérifiez que l\'émulateur est lancé '
      'et que l\'application a été installée avec `flutter run`.\n${result.stderr}',
    );
    return false;
  }
  // Écriture atomique : SQLite Viewer ne voit jamais un fichier à moitié copié.
  final tmp = File('$_target.tmp');
  await tmp.writeAsBytes(bytes, flush: true);
  await tmp.rename(_target);
  final now = DateTime.now().toIso8601String().substring(11, 19);
  stdout.writeln('[$now] $_target mis à jour (${(bytes.length / 1024).toStringAsFixed(0)} Ko)');
  return true;
}

String _findAdb() {
  final exe = Platform.isWindows ? 'adb.exe' : 'adb';
  final env = Platform.environment;
  final sdkRoots = [
    env['ANDROID_HOME'],
    env['ANDROID_SDK_ROOT'],
    if (env['LOCALAPPDATA'] != null) '${env['LOCALAPPDATA']}\\Android\\Sdk',
    if (env['HOME'] != null) '${env['HOME']}/Library/Android/sdk',
    if (env['HOME'] != null) '${env['HOME']}/Android/Sdk',
  ];
  for (final root in sdkRoots.whereType<String>()) {
    final candidate = File('$root${Platform.pathSeparator}platform-tools${Platform.pathSeparator}$exe');
    if (candidate.existsSync()) return candidate.path;
  }
  return 'adb'; // dans le PATH
}
