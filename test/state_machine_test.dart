import 'dart:convert';
import 'dart:io';

import '../lib/core/models.dart';
import '../lib/core/state_machine.dart';
import 'support/harness.dart';

/// Pure-Dart tests for the job lifecycle. Shared vectors are the same JSON file
/// the JavaScript mirror tests against, so a rule change breaks both sides.
void main() {
  final suite = TestSuite('job state machine');
  final vectors = jsonDecode(File('test/vectors/job_flow.json').readAsStringSync()) as Map<String, dynamic>;
  final states = (vectors['states'] as List).cast<String>();
  final edges = (vectors['edges'] as List).cast<List>();
  final forbidden = (vectors['forbidden'] as List).cast<List>();
  final guards = (vectors['guards'] as List).cast<Map<String, dynamic>>();
  final flows = vectors['flows'] as Map<String, dynamic>;

  suite.test('all twelve statuses are known', () {
    suite.equals(JobStatus.values.length, states.length, 'status count');
    for (final status in JobStatus.values) {
      suite.expect(states.contains(status.wire), 'missing wire value ${status.wire}');
    }
  });

  suite.test('the edge table matches the shared vectors', () {
    var count = 0;
    for (final entry in JobStateMachine.edges.entries) {
      count += entry.value.length;
    }
    suite.equals(count, edges.length, 'edge count');
    for (final edge in edges) {
      final from = JobStatusWire.parse(edge[0] as String);
      final to = JobStatusWire.parse(edge[1] as String);
      suite.expect(JobStateMachine.edges[from]!.contains(to), '$from -> $to should be allowed');
    }
  });

  suite.test('forbidden edges are rejected', () {
    for (final edge in forbidden) {
      final from = JobStatusWire.parse(edge[0] as String);
      final to = JobStatusWire.parse(edge[1] as String);
      final result = JobStateMachine.canTransition(
        from,
        to,
        workerId: 'w_1',
        escrowHeld: true,
        proofUploaded: true,
        feeAccepted: true,
        reason: 'customer reported a leak',
        withinDisputeWindow: true,
        reviewComplete: true,
      );
      suite.expect(!result.ok, '$from -> $to should be rejected');
    }
  });

  suite.test('guards follow the recorded contexts', () {
    for (final item in guards) {
      final from = JobStatusWire.parse(item['from'] as String);
      final to = JobStatusWire.parse(item['to'] as String);
      final context = Map<String, dynamic>.from(item['context'] as Map);
      final result = JobStateMachine.canTransition(
        from,
        to,
        workerId: context['workerId'] as String?,
        escrowHeld: context['escrowHeld'] as bool? ?? false,
        proofUploaded: context['proofUploaded'] as bool? ?? false,
        feeAccepted: context['feeAccepted'] as bool? ?? false,
        reason: context['reason'] as String? ?? '',
        withinDisputeWindow: context['withinDisputeWindow'] as bool? ?? false,
        reviewComplete: context['reviewComplete'] as bool? ?? false,
      );
      suite.equals(result.ok, item['allowed'], '${item['from']} -> ${item['to']}');
    }
  });

  suite.test('illegal transitions throw and do not mutate the job', () {
    final job = JobStateMachine.createJob(id: 'GK-1', serviceId: 'svc', customerId: 'c_1');
    var threw = false;
    try {
      JobStateMachine.transition(job, JobStatus.paid);
    } on StateError {
      threw = true;
    }
    suite.expect(threw, 'paid from draft should throw');
    suite.equals(job.status, JobStatus.draft, 'input job status');
    final requested = JobStateMachine.transition(job, JobStatus.requested);
    suite.equals(requested.status, JobStatus.requested, 'next status');
    suite.equals(job.history.length, 0, 'history should stay on the new snapshot');
    suite.equals(requested.history.length, 1, 'history recorded');
  });

  suite.test('the three recorded flows complete', () {
    for (final name in ['happy', 'dispute', 'cancel']) {
      final path = (flows[name] as List).map((value) => JobStatusWire.parse(value as String)).toList();
      final job = JobStateMachine.createJob(id: 'GK-2', serviceId: 'svc', customerId: 'c_1');
      final finalJob = JobStateMachine.runPath(job, path);
      suite.equals(finalJob.status.name, path.last.name, '$name final status');
      suite.equals(finalJob.history.length, path.length, '$name history length');
      suite.expect(finalJob.isTerminal, '$name should close');
    }
  });

  suite.test('escrow is derived, not stored a second time', () {
    final base = JobStateMachine.createJob(id: 'GK-3', serviceId: 'svc', customerId: 'c_1');
    suite.equals(base.escrow, EscrowState.held, 'new job');
    suite.equals(base.copyWith(status: JobStatus.completed).escrow, EscrowState.releasable, 'completed');
    suite.equals(base.copyWith(status: JobStatus.paid).escrow, EscrowState.released, 'paid');
    suite.equals(base.copyWith(status: JobStatus.disputed).escrow, EscrowState.frozen, 'disputed');
  });

  suite.test('quote totals and disputes validate', () {
    const quote = Quote(serviceId: 'svc_cleaning', amount: 3200, visitFee: 200);
    suite.equals(quote.total, 3400, 'quote total');
    suite.equals(quote.formatted, 'NPR 3,400', 'formatted total');
    final bad = Dispute(jobId: 'GK-1', reason: 'drip', openedAt: DateTime.utc(2026, 10, 28));
    suite.expect(!bad.isValid, 'short dispute reason should fail');
    final good = Dispute(jobId: 'GK-1', reason: 'the tap still drips after the visit', openedAt: DateTime.utc(2026, 10, 28));
    suite.expect(good.isValid, 'specific reason should pass');
  });

  suite.run();
}
