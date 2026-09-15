import 'package:flutter/material.dart';

import 'core/mock_data.dart';
import 'core/models.dart';
import 'screens/booking_screen.dart';
import 'screens/dispute_screen.dart';
import 'screens/job_tracking_screen.dart';
import 'screens/kyc_screen.dart';
import 'screens/services_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/wallet_screen.dart';
import 'screens/worker_profile_screen.dart';

/// Route table for the sample. The production app uses the same paths behind a
/// declarative router; here a plain onGenerateRoute keeps the sample free of
/// third-party packages so it can be read and analysed without a network fetch.
class AppRouter {
  static const splash = '/splash';
  static const services = '/services';
  static const booking = '/booking';
  static const workers = '/workers';
  static const kyc = '/kyc';
  static const tracking = '/jobs/track';
  static const wallet = '/wallet';
  static const dispute = '/jobs/dispute';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute<void>(builder: (_) => const SplashScreen(), settings: settings);
      case services:
        return MaterialPageRoute<void>(builder: (_) => const ServicesScreen(), settings: settings);
      case booking:
        final serviceId = settings.arguments is String ? settings.arguments as String : 'svc_plumbing';
        return MaterialPageRoute<void>(
          builder: (_) => BookingScreen(serviceId: serviceId),
          settings: settings,
        );
      case workers:
        final worker = settings.arguments is Worker ? settings.arguments as Worker : seedWorkers.first;
        return MaterialPageRoute<void>(
          builder: (_) => WorkerProfileScreen(worker: worker),
          settings: settings,
        );
      case kyc:
        return MaterialPageRoute<void>(builder: (_) => const KycScreen(), settings: settings);
      case tracking:
        final job = settings.arguments is Job ? settings.arguments as Job : sampleJob();
        return MaterialPageRoute<void>(
          builder: (_) => JobTrackingScreen(job: job),
          settings: settings,
        );
      case wallet:
        return MaterialPageRoute<void>(builder: (_) => const WalletScreen(), settings: settings);
      case dispute:
        final job = settings.arguments is Job ? settings.arguments as Job : sampleJob(status: JobStatus.disputed);
        return MaterialPageRoute<void>(
          builder: (_) => DisputeScreen(job: job),
          settings: settings,
        );
      default:
        return MaterialPageRoute<void>(builder: (_) => const SplashScreen(), settings: settings);
    }
  }
}
