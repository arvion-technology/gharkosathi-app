import 'models.dart';

/// Seeded data for the sample app. Prices are in Nepali rupees. Names are sample
/// content, not real workers.
final List<Service> seedServices = [
  const Service(id: 'svc_plumbing', name: 'Plumbing', category: 'Repair', basePrice: 2400, durationMinutes: 90),
  const Service(id: 'svc_electrical', name: 'Electrical', category: 'Repair', basePrice: 1800, durationMinutes: 60),
  const Service(id: 'svc_cleaning', name: 'Deep cleaning', category: 'Home', basePrice: 3200, durationMinutes: 180),
  const Service(id: 'svc_ac', name: 'AC service', category: 'Appliance', basePrice: 2800, durationMinutes: 120),
];

final List<Worker> seedWorkers = [
  const Worker(
    id: 'w_sita',
    name: 'Sita Gurung',
    skill: 'Plumbing',
    rating: 4.9,
    jobsCompleted: 312,
    kyc: KycState.verified,
  ),
  const Worker(
    id: 'w_ramesh',
    name: 'Ramesh Karki',
    skill: 'Electrical',
    rating: 4.7,
    jobsCompleted: 188,
    kyc: KycState.verified,
  ),
  const Worker(
    id: 'w_anita',
    name: 'Anita Shrestha',
    skill: 'Deep cleaning',
    rating: 4.8,
    jobsCompleted: 240,
    kyc: KycState.verified,
  ),
  const Worker(
    id: 'w_bikash',
    name: 'Bikash Tamang',
    skill: 'Plumbing',
    rating: 4.4,
    jobsCompleted: 61,
    kyc: KycState.inReview,
  ),
];

final List<WalletEntry> seedWallet = [
  WalletEntry(id: 'tx_1', label: 'Top-up · eSewa', amount: 5000, createdAt: DateTime.utc(2026, 10, 24)),
  WalletEntry(id: 'tx_2', label: 'Deep cleaning · GK-2479', amount: -1800, createdAt: DateTime.utc(2026, 10, 26)),
  WalletEntry(id: 'tx_3', label: 'Plumbing · GK-2476', amount: -2400, createdAt: DateTime.utc(2026, 10, 20)),
];

/// One sample job used by the tracking and wallet screens when the app opens
/// without a live booking.
Job sampleJob({JobStatus status = JobStatus.matched}) {
  final created = DateTime.utc(2026, 10, 28, 8, 30);
  return Job(
    id: 'GK-2481',
    serviceId: 'svc_plumbing',
    customerId: 'c_demo',
    workerId: 'w_sita',
    address: 'Baneshwor, Kathmandu',
    status: status,
    escrowHeld: true,
    createdAt: created,
    updatedAt: created.add(const Duration(hours: 1)),
  );
}
