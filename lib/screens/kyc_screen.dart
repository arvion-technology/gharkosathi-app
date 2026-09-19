import 'package:flutter/material.dart';

import '../core/models.dart';
import '../theme/arvion_theme.dart';

class KycScreen extends StatefulWidget {
  const KycScreen({super.key});

  @override
  State<KycScreen> createState() => _KycScreenState();
}

class _KycScreenState extends State<KycScreen> {
  int _step = 0;
  KycState _state = KycState.notStarted;
  final Set<String> _captured = {};

  static const _captures = [
    ('Citizenship · front', 'identity'),
    ('Citizenship · back', 'identity'),
    ('Selfie for liveness', 'selfie'),
    ('Skill certificate', 'skill'),
  ];

  void _capture(String id) {
    setState(() {
      _captured.add(id);
      _step = (_captured.length / 2).floor().clamp(0, 2).toInt();
      if (_captured.length == _captures.length) _state = KycState.documentsUploaded;
    });
  }

  void _submit() {
    setState(() => _state = KycState.inReview);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Documents submitted. A reviewer checks them within 24 hours.'),
        backgroundColor: ArvionColors.surface2,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verify your identity')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
        children: [
          Row(
            children: [
              for (var index = 0; index < 3; index++) ...[
                _stepDot(index),
                if (index < 2) const Expanded(child: Divider(height: 1)),
              ],
            ],
          ),
          const SizedBox(height: 18),
          if (_state == KycState.inReview)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.hourglass_top, color: ArvionColors.gold),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text('In review. You can accept jobs after verification, not before.'),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 12),
          ..._captures.map((capture) {
            final done = _captured.contains(capture.$2);
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Card(
                child: ListTile(
                  leading: Icon(
                    done ? Icons.check_circle : Icons.add_a_photo_outlined,
                    color: done ? ArvionColors.green : ArvionColors.muted,
                  ),
                  title: Text(capture.$1),
                  subtitle: Text(done ? 'Captured on this device' : 'Not captured yet'),
                  trailing: done
                      ? null
                      : TextButton(
                          onPressed: _state == KycState.inReview ? null : () => _capture(capture.$2),
                          child: const Text('Capture'),
                        ),
                ),
              ),
            );
          }),
          const SizedBox(height: 10),
          const Text(
            'A reviewer checks the identity match and the certificate. KYC is a state machine of its own: '
            'notStarted → documentsUploaded → inReview → verified or rejected, and a rejected application '
            'can resubmit without losing the captured files.',
            style: TextStyle(fontSize: 12.5, color: ArvionColors.muted, height: 1.5),
          ),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: _state == KycState.documentsUploaded ? _submit : null,
            child: Text(_state == KycState.inReview ? 'Submitted' : 'Submit for review'),
          ),
        ],
      ),
    );
  }

  Widget _stepDot(int index) {
    final active = _step >= index;
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active ? ArvionColors.gold : ArvionColors.surface2,
        border: Border.all(color: active ? ArvionColors.gold : ArvionColors.line),
      ),
      child: Center(
        child: Text(
          '${index + 1}',
          style: TextStyle(
            color: active ? const Color(0xFF1A1405) : ArvionColors.muted,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
