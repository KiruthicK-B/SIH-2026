import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/gen/app_localizations.dart';
import '../state/locale_controller.dart';
import 'router.dart';
import 'theme.dart';

class AgrivaApp extends ConsumerWidget {
  const AgrivaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final locale = ref.watch(localeControllerProvider);
    final themeMode = ref.watch(themeModeControllerProvider);

    return MaterialApp.router(
      title: 'Agriva',
      debugShowCheckedModeBanner: false,
      theme: AgrivaTheme.light,
      darkTheme: AgrivaTheme.dark,
      themeMode: themeMode,
      locale: locale,
      supportedLocales: supportedAgrivaLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: router,
    );
  }
}
