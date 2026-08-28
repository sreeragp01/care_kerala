import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/localization/app_localizations.dart';
import 'core/state/app_state_provider.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/screens/login_screen.dart';

import 'package:flutter/foundation.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Phase 9: Global Flutter UI Error Handling
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    final ref = 'ERR-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    debugPrint('CareLink Global Error Captured [$ref]: ${details.exceptionAsString()}');
  };

  // Phase 9: Global Asynchronous Platform Error Handling
  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    final ref = 'ERR-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    debugPrint('CareLink Async Platform Error [$ref]: $error');
    return true;
  };

  final appState = AppStateProvider();
  runApp(CareLinkKeralaApp(state: appState));
}


class CareLinkKeralaApp extends StatelessWidget {
  final AppStateProvider state;

  const CareLinkKeralaApp({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: state,
      builder: (context, _) {
        return MaterialApp(
          title: 'CareLink Kerala',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: state.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          locale: state.locale,
          supportedLocales: const [
            Locale('en', ''),
            Locale('ml', ''),
          ],
          localizationsDelegates: const [
            AppLocalizationsDelegate(),
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: LoginScreen(state: state),
        );
      },
    );
  }
}
