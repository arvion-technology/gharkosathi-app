import 'package:flutter/material.dart';

import '../core/models.dart';
import '../core/offline_queue.dart';
import '../core/state_machine.dart';
import '../theme/arvion_theme.dart';

/// Job tracking is where offline-first behaviour is visible to the customer.
/// A status change made without signal is queued; the timeline marks it pending
/// until the queue flushes, and the queue is persisted so a kill does not lose it.
class JobTrackingScreen extends StatefulWidget {
  const JobTrackingScreen({super.key, required this.job});

  final Job job;

  @override
  State<JobTrackingScreen> createState() => _JobTrackingScreenState();
}

class _JobTrackingScreenState extends State<JobTrackingScreen> {
  late Job _job = widget.job;
  final OfflineQueue _queue = OfflineQueue();
  bool _online = false;
  String? _notice;

  static const _steps = [
    (JobStatus.requested, 'Requested'),
    (JobStatus.matching, 'Matching'),
    (JobStatus.matched, 'Worker matched'),
    (JobStatus.enRoute, 'On the way'),
    (JobStatus.inProgress, 'In progress'),
    (JobStatus.completed, 'Completed'),
    (JobStatus.paid, 'Paid'),
  ];

  int get _reached {
    final index = _steps.indexWhere((step) => step.$1 == _job.status);
    return index == -1 ? 0 : index;
  }

  JobStatus? get _nextStatus {
    final targets = JobStateMachine.edges[_job.status] ?? const <JobStatus>{};
    if (targets.contains(JobStatus.enRoute)) return JobStatus.enRoute;
    if (targets.contains(JobStatus.inProgress)) return JobStatus.inProgress;
    if (targets.contains(JobStatus.completed)) return JobStatus.completed;
    return null;
  }

  Future<void> _advance() async {
    final target = _nextStatus;
    if (target == null) return;
    final key = '${_job.id}:${target.wire}';
    _queue.enqueue(key: key, type: 'job.status', payload: {'status': target.wire});
    if (!_online) {
      setState(() => _notice = 'Saved offline. The update will send when signal returns.');
      return;
    }
    await _flush();
  }

  Future<void> _flush() async {
    final result = await _queue.flush((operation) async {
      // The production client posts the operation id as an Idempotency-Key.
      setState(() {
        _job = JobStateMachine.transition(
          _job,
          JobStatusWire.parse(operation.payload['status'] as String),
          workerId: _job.workerId ?? 'w_sita',
        );
      });
      return true;
    });
    setState(() {
      _notice = result.sent > 0
          ? '${result.sent} update sent. Timeline is current.'
          : 'Nothing queued to send.';
    });
  }

  Future<void> _toggleOnline(bool value) async {
    setState(() => _online = value);
    if (value && !_queue.isDrained) {
      await _flush();
      if (!mounted) return;
      setState(() => _online = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Job ${_job.id}')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.signal_cellular_alt, size: 18, color: ArvionColors.muted),
                  const SizedBox(width: 8),
                  Text(_online ? 'Online' : 'Offline', style: const TextStyle(fontWeight: FontWeight.w600)),
                  const Spacer(),
                  Switch(
                    value: _online,
                    activeThumbColor: ArvionColors.gold,
                    onChanged: _toggleOnline,
                  ),
                ],
              ),
            ),
          ),
          if (_notice != null) ...[
            const SizedBox(height: 10),
            Text(_notice!, style: const TextStyle(fontSize: 12.5, color: ArvionColors.gold)),
          ],
          const SizedBox(height: 18),
          ...List.generate(_steps.length, (index) {
            final (_, label) = _steps[index];
            final done = index <= _reached;
            final current = index == _reached;
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: done ? ArvionColors.gold : ArvionColors.surface2,
                        border: Border.all(color: done ? ArvionColors.gold : ArvionColors.line),
                      ),
                    ),
                    if (index < _steps.length - 1)
                      Container(
                        width: 1,
                        height: 38,
                        color: done ? ArvionColors.gold : ArvionColors.line,
                      ),
                  ],
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 18),
                    child: Text(
                      label,
                      style: TextStyle(
                        color: current
                            ? ArvionColors.text
                            : done
                                ? ArvionColors.text2
                                : ArvionColors.muted,
                        fontWeight: current ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ),
                ),
                if (current && !_queue.isDrained)
                  const Text('pending', style: TextStyle(fontSize: 11, color: ArvionColors.gold)),
              ],
            );
          }),
          const SizedBox(height: 6),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: ArvionColors.surface2,
                    child: Text('SG', style: TextStyle(fontSize: 12, color: ArvionColors.gold)),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Sita Gurung', style: TextStyle(fontWeight: FontWeight.w600)),
                        Text('Verified plumber · 12 min away', style: TextStyle(fontSize: 12, color: ArvionColors.muted)),
                      ],
                    ),
                  ),
                  if (!_queue.isDrained)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0x1AF5C26B),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text('${_queue.size} queued', style: const TextStyle(fontSize: 10.5, color: ArvionColors.gold)),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _nextStatus == null ? null : _advance,
            child: Text(_nextStatus == null ? 'Timeline complete' : 'Mark ${_nextStatus!.name}'),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: () => Navigator.of(context).pushReplacementNamed('/jobs/dispute', arguments: _job),
            child: const Text('Open a dispute'),
          ),
        ],
      ),
    );
  }
}
