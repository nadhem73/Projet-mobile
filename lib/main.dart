import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medilab_prokit/core/navigation/app_router.dart';
import 'package:medilab_prokit/core/state/app_store.dart';
import 'package:medilab_prokit/core/state/service_locator.dart';
import 'package:medilab_prokit/core/theme/app_theme.dart';
import 'package:medilab_prokit/core/utils/mock_data.dart';
import 'package:nb_utils/nb_utils.dart';

late final AppStore appStore;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initialize(aLocaleLanguageList: languageList());

  fontFamilyPrimaryGlobal = GoogleFonts.plusJakartaSans().fontFamily;
  fontFamilySecondaryGlobal = GoogleFonts.plusJakartaSans().fontFamily;

  await setupDependencies();
  appStore = getIt<AppStore>();
  await appStore.toggleDarkMode(value: getBoolAsync('isDarkModeOnPref'));

  defaultRadius = 12;
  defaultToastGravityGlobal = ToastGravity.BOTTOM;

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (_) => MaterialApp.router(
        debugShowCheckedModeBanner: false,
        title: 'Medilink Tunisia${!isMobile ? ' ${platformName()}' : ''}',
        routerConfig: appRouter,
        theme: !appStore.isDarkModeOn ? AppThemeData.lightTheme : AppThemeData.darkTheme,
        scrollBehavior: SBehavior(),
        supportedLocales: LanguageDataModel.languageLocales(),
        localeResolutionCallback: (locale, supportedLocales) => locale,
      ),
    );
  }
}