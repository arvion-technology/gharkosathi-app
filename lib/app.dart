import 'package:flutter/material.dart';

import '../router.dart';
import '../theme/arvion_theme.dart';

/// App shell. The production build reads the session from secure storage before
/// deciding the first route; the sample keeps that decision in SplashScreen so the
/// case study can show the state without pretending to have an auth backend.
class GharKoApp extends StatelessWidget {
  const GharKoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GharKo Sathi',
      debugShowCheckedModeBanner: false,
      theme: ArvionTheme.dark,
      initialRoute: AppRouter.splash,
      onGenerateRoute: AppRouter.onGenerateRoute,
    );
  }
}
