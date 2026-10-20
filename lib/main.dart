import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:medilink/app/app_modules.dart';
import 'package:medilink/app/medilink_app.dart';
import 'package:medilink/core/di/injection.dart';
import 'package:medilink/core/state/app_store.dart';
import 'package:medilink/core/theme/app_colors.dart';
import 'package:medilink/core/theme/app_typography.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

/// Store global (mode sombre) utilisé par les écrans hérités du template.
/// Nouveau code : `getIt<AppStore>()`.
late final AppStore appStore;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // nb_utils (utilisé par les écrans hérités du template)
  await initialize();
  fontFamilyPrimaryGlobal = AppTypography.bodyFamily;
  fontFamilySecondaryGlobal = AppTypography.bodyFamily;
  defaultRadius = 14;
  defaultToastGravityGlobal = ToastGravity.BOTTOM;
  appButtonBackgroundColorGlobal = AppColors.primary;

  await initializeDateFormatting('fr');

  // Sur le Web (démo dans Chrome), SQLite passe par WebAssembly.
  if (kIsWeb) databaseFactory = databaseFactoryFfiWeb;
  await configureDependencies(appModules);

  appStore = getIt<AppStore>();
  await appStore.toggleDarkMode(value: getBoolAsync('isDarkModeOnPref'));

  runApp(const MediLinkApp());
}
