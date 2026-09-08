import 'mock_data.dart';
import 'models.dart';
import 'state_machine.dart';

/// The boundary between screens and the backend. Screens depend on this, not on
/// HTTP. The in-memory implementation below is what the case study runs; the
/// production app swaps in an HTTP implementation with the same signatures.
abstract class HomeServicesRepository {
  Future<List<Service>> services();
  Future<List<Worker>> workersFor(String skill);
  Future<Quote> quoteFor(String serviceId);
  Future<List<Job>> jobsFor(String customerId);
  Future<Job> requestJob({required String serviceId, required String address});
  Future<Job> applyStatus(Job job, JobStatus to, {String? workerId, String note = ''});
}

class InMemoryRepository implements HomeServicesRepository {
  InMemoryRepository({this.latency = const Duration(milliseconds: 180)});

  final Duration latency;
  final List<Job> _jobs = [];
  var _ids = 2480;

  Future<void> _settle() => Future<void>.delayed(latency);

  @override
  Future<List<Service>> services() async {
    await _settle();
    return seedServices;
  }

  @override
  Future<List<Worker>> workersFor(String skill) async {
    await _settle();
    return seedWorkers.where((worker) => worker.skill == skill && worker.isVerified).toList();
  }

  @override
  Future<Quote> quoteFor(String serviceId) async {
    await _settle();
    final service = seedServices.firstWhere((item) => item.id == serviceId);
    return Quote(serviceId: serviceId, amount: service.basePrice, visitFee: 200);
  }

  @override
  Future<List<Job>> jobsFor(String customerId) async {
    await _settle();
    return _jobs.where((job) => job.customerId == customerId).toList();
  }

  @override
  Future<Job> requestJob({required String serviceId, required String address}) async {
    await _settle();
    _ids += 1;
    final job = Job(
      id: 'GK-$_ids',
      serviceId: serviceId,
      customerId: 'c_demo',
      address: address,
      status: JobStatus.requested,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _jobs.add(job);
    return job;
  }

  @override
  Future<Job> applyStatus(Job job, JobStatus to, {String? workerId, String note = ''}) async {
    await _settle();
    final updated = JobStateMachine.transition(
      job,
      to,
      workerId: workerId,
      feeAccepted: true,
      reason: 'customer reported an issue with the work',
      withinDisputeWindow: true,
      reviewComplete: true,
      note: note,
    );
    final index = _jobs.indexWhere((item) => item.id == job.id);
    if (index >= 0) _jobs[index] = updated;
    return updated;
  }
}
