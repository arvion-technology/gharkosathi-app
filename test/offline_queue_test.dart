import 'dart:io';

import '../lib/core/offline_queue.dart';
import 'support/harness.dart';

/// Pure-Dart tests for the offline queue. Run with:
///   dart test/offline_queue_test.dart
Future<void> main() async {
  final suite = TestSuite('offline queue');

  await suite.testAsync('deduplicates by idempotency key', () async {
    final queue = OfflineQueue();
    suite.equals(queue.enqueue(key: 'job:1', type: 'status'), true, 'first enqueue');
    suite.equals(queue.enqueue(key: 'job:1', type: 'status'), false, 'duplicate enqueue');
    suite.equals(queue.size, 1, 'queue size');
  });

  await suite.testAsync('flush sends in order, stops on failure', () async {
    final queue = OfflineQueue();
    queue.enqueue(key: 'a', type: 'status');
    queue.enqueue(key: 'b', type: 'status');
    queue.enqueue(key: 'c', type: 'status');
    final sent = <String>[];
    final result = await queue.flush((operation) async {
      if (operation.key == 'b') return false;
      sent.add(operation.key);
      return true;
    });
    suite.equals(sent.join(','), 'a', 'sent order');
    suite.equals(result.sent, 1, 'sent count');
    suite.equals(result.remaining, 2, 'remaining');
    suite.equals(result.failed.first.key, 'b', 'first failure');
    suite.expect(result.retryIn > Duration.zero, 'retry should be scheduled');
  });

  await suite.testAsync('a later update cannot overtake an earlier one', () async {
    final queue = OfflineQueue();
    queue.enqueue(key: 'step-1', type: 'status');
    queue.enqueue(key: 'step-2', type: 'status');
    await queue.flush((operation) async => false);
    suite.equals(queue.first!.key, 'step-1', 'still blocked on first');
    final sent = <String>[];
    await queue.flush((operation) async {
      sent.add(operation.key);
      return true;
    });
    suite.equals(sent.join(','), 'step-1,step-2', 'drained order');
    suite.expect(queue.isDrained, 'queue should drain');
  });

  await suite.testAsync('backoff doubles and is capped', () async {
    suite.equals(OfflineQueue.backoffFor(0), Duration.zero, 'attempt 0');
    suite.equals(OfflineQueue.backoffFor(1), const Duration(seconds: 1), 'attempt 1');
    suite.equals(OfflineQueue.backoffFor(3), const Duration(seconds: 4), 'attempt 3');
    suite.equals(OfflineQueue.backoffFor(9), const Duration(seconds: 30), 'cap');
  });

  await suite.testAsync('exhaustion is reported after the attempt limit', () async {
    final queue = OfflineQueue();
    queue.enqueue(key: 'x', type: 'status');
    FlushResult? last;
    for (var index = 0; index < OfflineQueue.maxAttempts; index++) {
      last = await queue.flush((operation) async => false);
    }
    suite.equals(last!.exhausted, true, 'exhausted');
    suite.equals(last.remaining, 1, 'still queued for a manual decision');
  });

  await suite.testAsync('persists across an app kill', () async {
    final queue = OfflineQueue();
    queue.enqueue(key: 'a', type: 'status', payload: {'status': 'inProgress'});
    queue.enqueue(key: 'b', type: 'status', payload: {'status': 'completed'});
    await queue.flush((operation) async => false);
    final saved = queue.serialize();
    final restored = OfflineQueue();
    suite.equals(restored.restore(saved), 2, 'restored count');
    suite.equals(restored.first!.key, 'a', 'order preserved');
    suite.equals(restored.first!.attempts, 1, 'attempts preserved');
    suite.equals(restored.pending[1].payload['status'], 'completed', 'payload preserved');
  });

  await suite.testAsync('discard removes a poison operation', () async {
    final queue = OfflineQueue();
    queue.enqueue(key: 'bad', type: 'status');
    queue.enqueue(key: 'good', type: 'status');
    await queue.flush((operation) async => operation.key != 'bad');
    suite.equals(queue.discard('bad'), true, 'discard');
    suite.equals(queue.discard('bad'), false, 'second discard');
    suite.equals(queue.size, 1, 'one left');
  });

  suite.run();
}
