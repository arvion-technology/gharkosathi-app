import 'package:flutter/material.dart';

import '../router.dart';
import '../theme/arvion_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    // The production build reads the token from secure storage and refreshes it
    // here. On failure the user goes to onboarding instead of the service feed.
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed(AppRouter.services);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 86,
              height: 86,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0x66F5C26B)),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF1B2440), Color(0xFF0D1220)],
                ),
              ),
              child: const Center(
                child: Text(
                  'GK',
                  style: TextStyle(
                    fontFamily: 'serif',
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                    color: ArvionColors.gold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 22),
            Text('GharKo Sathi', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 6),
            const Text('Home services, verified.', style: TextStyle(color: ArvionColors.muted)),
            const SizedBox(height: 26),
            const SizedBox(
              width: 140,
              child: LinearProgressIndicator(
                minHeight: 3,
                backgroundColor: ArvionColors.surface2,
                color: ArvionColors.gold,
              ),
            ),
            const SizedBox(height: 10),
            const Text('Restoring session', style: TextStyle(fontSize: 12, color: ArvionColors.muted)),
          ],
        ),
      ),
    );
  }
}
