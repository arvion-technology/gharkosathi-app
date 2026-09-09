import 'models.dart';

/// The job lifecycle. Pure Dart, no Flutter imports: the same class is used by
/// the customer app, the worker app and the admin queue, and it is tested without
/// a widget tree. Mirrored in src/state-machine.js for the case-study site; both
/// read test/vectors/job_flow.json.

class TransitionCheck {
  const TransitionCheck(this.ok, this.reason);
  final bool ok;
  final String reason;
}

class JobStateMachine {
  static const Map<JobStatus, Set<JobStatus>> edges = {
    JobStatus.draft: {JobStatus.requested},
    JobStatus.requested: {JobStatus.matching, JobStatus.cancelled},
    JobStatus.matching: {JobStatus.matched, JobStatus.requested, JobStatus.cancelled},
    JobStatus.matched: {JobStatus.enRoute, JobStatus.cancelled, JobStatus.disputed},
    JobStatus.enRoute: {JobStatus.inProgress, JobStatus.cancelled, JobStatus.disputed},
    JobStatus.inProgress: {JobStatus.completed, JobStatus.disputed},
    JobStatus.completed: {JobStatus.paid, JobStatus.disputed},
    JobStatus.paid: {JobStatus.disputed, JobStatus.closed},
    JobStatus.disputed: {JobStatus.refunded, JobStatus.paid, JobStatus.closed},
    JobStatus.refunded: {JobStatus.closed},
    JobStatus.cancelled: {JobStatus.closed},
    JobStatus.closed: <JobStatus>{},
  };

  static TransitionCheck canTransition(
    JobStatus from,
    JobStatus to, {
    String? workerId,
    bool escrowHeld = false,
    bool proofUploaded = false,
    bool feeAccepted = false,
    String reason = '',
    bool withinDisputeWindow = false,
    bool reviewComplete = false,
  }) {
    if (!edges[from]!.contains(to)) {
      return TransitionCheck(false, '${from.wire} cannot move to ${to.wire}');
    }
    switch ((from, to)) {
      case (JobStatus.matching, JobStatus.matched):
        return workerId == null || workerId.isEmpty
            ? const TransitionCheck(false, 'matching -> matched requires a worker')
            : const TransitionCheck(true, 'allowed');
      case (JobStatus.completed, JobStatus.paid):
        return escrowHeld && proofUploaded
            ? const TransitionCheck(true, 'allowed')
            : const TransitionCheck(false, 'paid requires held escrow and completion proof');
      case (JobStatus.matched || JobStatus.enRoute, JobStatus.cancelled):
        return feeAccepted
            ? const TransitionCheck(true, 'allowed')
            : const TransitionCheck(false, 'late cancellation needs the fee accepted');
      case (JobStatus.inProgress || JobStatus.completed, JobStatus.disputed):
        return reason.trim().length >= 10
            ? const TransitionCheck(true, 'allowed')
            : const TransitionCheck(false, 'a dispute needs a reason of at least 10 characters');
      case (JobStatus.paid, JobStatus.disputed):
        return withinDisputeWindow
            ? const TransitionCheck(true, 'allowed')
            : const TransitionCheck(false, 'the dispute window has closed');
      case (JobStatus.disputed, JobStatus.refunded):
        return reviewComplete
            ? const TransitionCheck(true, 'allowed')
            : const TransitionCheck(false, 'refund needs a completed review');
      default:
        return const TransitionCheck(true, 'allowed');
    }
  }

  /// Applies one edge and appends an audit event. Returns a new Job, never mutates.
  static Job transition(
    Job job,
    JobStatus to, {
    String? workerId,
    bool feeAccepted = false,
    String reason = '',
    bool withinDisputeWindow = false,
    bool reviewComplete = false,
    DateTime? at,
    String note = '',
  }) {
    final check = canTransition(
      job.status,
      to,
      workerId: workerId ?? job.workerId,
      escrowHeld: job.escrowHeld,
      proofUploaded: job.proofUploaded,
      feeAccepted: feeAccepted,
      reason: reason,
      withinDisputeWindow: withinDisputeWindow,
      reviewComplete: reviewComplete,
    );
    if (!check.ok) throw StateError('illegal transition: ${check.reason}');
    final now = at ?? DateTime.now();
    return job.copyWith(
      status: to,
      workerId: workerId,
      updatedAt: now,
      history: [
        ...job.history,
        JobEvent(from: job.status, to: to, at: now, note: note),
      ],
    );
  }

  /// Walks a path. Used by tests and by the case-study flow diagram.
  static Job runPath(Job job, List<JobStatus> path, {DateTime? startAt}) {
    var current = job;
    final base = startAt ?? DateTime.utc(2026, 10, 28, 9);
    for (var index = 0; index < path.length; index++) {
      final target = path[index];
      // Completion uploads the proof in the same interaction that moves the job
      // to completed; without it the escrow guard correctly blocks payment.
      if (target == JobStatus.paid && !current.proofUploaded) {
        current = current.copyWith(proofUploaded: true);
      }
      current = transition(
        current,
        target,
        workerId: current.workerId ?? 'w_seed',
        feeAccepted: true,
        reason: 'dispute reason for the vector',
        withinDisputeWindow: true,
        reviewComplete: true,
        at: base.add(Duration(minutes: index)),
      );
    }
    return current;
  }

  static Job createJob({
    required String id,
    required String serviceId,
    required String customerId,
    String address = '',
    DateTime? createdAt,
  }) {
    final now = createdAt ?? DateTime.now();
    return Job(
      id: id,
      serviceId: serviceId,
      customerId: customerId,
      address: address,
      status: JobStatus.draft,
      createdAt: now,
      updatedAt: now,
    );
  }
}
