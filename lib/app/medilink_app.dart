import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:go_router/go_router.dart';
import 'package:medilink/app/app_modules.dart';
import 'package:medilink/app/app_router.dart';
import 'package:medilink/core/config/app_config.dart';
import 'package:medilink/core/di/injection.dart';
import 'package:medilink/core/session/session_service.dart';
import 'package:medilink/core/state/app_store.dart';
import 'package:medilink/core/theme/app_theme.dart';
import 'package:nb_utils/nb_utils.dart';

class MediLinkApp extends StatefulWidget {
  const MediLinkApp({super.key});

  @override
  State<MediLinkApp> createState() => _MediLinkAppState();
}

class _MediLinkAppState extends State<MediLinkApp> {
  late final GoRouter _router = buildAppRouter(modules: appModules, session: getIt<SessionService>());

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appStore = getIt<AppStore>();
    return Observer(
      builder:
          (_) => MaterialApp.router(
            title: AppConfig.appName,
            debugShowCheckedModeBanner: false,
            routerConfig: _router,
            theme: AppThemeData.lightTheme,
            darkTheme: AppThemeData.darkTheme,
            themeMode: appStore.isDarkModeOn ? ThemeMode.dark : ThemeMode.light,
            scrollBehavior: SBehavior(),
            locale: const Locale('fr'),
            supportedLocales: const [Locale('fr'), Locale('en'), Locale('ar')],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
          ),
    );
  }
}
