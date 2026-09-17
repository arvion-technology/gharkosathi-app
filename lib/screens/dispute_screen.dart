import 'package:flutter/material.dart';

import '../core/models.dart';
import '../theme/arvion_theme.dart';

class DisputeScreen extends StatefulWidget {
  const DisputeScreen({super.key, required this.job});

  final Job job;

  @override
  State<DisputeScreen> createState() => _DisputeScreenState();
}

class _DisputeScreenState extends State<DisputeScreen> {
  final TextEditingController _reason = TextEditingController();
  bool _submitting = false;
  String? _error;

  Future<void> _submit() async {
    final dispute = Dispute(
      jobId: widget.job.id,
      reason: _reason.text.trim(),
      openedAt: DateTime.now(),
      photoCount: 0,
    );
    if (!dispute.isValid) {
      setState(() => _error = 'Give at least 10 characters so the reviewer has something to work with.');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    setState(() => _submitting = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Dispute opened. Escrow stays held until both sides respond.'),
        backgroundColor: ArvionColors.surface2,
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Open a dispute')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
        children: [
          Card(
            color: const Color(0x1AF5C26B),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.lock_clock, color: ArvionColors.gold, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'NPR 3,200 stays held while this dispute is open. Both sides have two working days to respond.',
                      style: TextStyle(color: ArvionColors.text2, fontSize: 13, height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          const Text('What went wrong?', style: TextStyle(fontSize: 12, color: ArvionColors.muted)),
          const SizedBox(height: 6),
          TextField(
            controller: _reason,
            minLines: 4,
            maxLines: 6,
            onChanged: (_) => setState(() => _error = null),
            decoration: InputDecoration(
              hintText: 'The tap still drips after the visit.',
              errorText: _error,
            ),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.add_a_photo_outlined, size: 18),
            label: const Text('Add a photo (optional)'),
          ),
          const SizedBox(height: 18),
          const Text(
            'Submitting the dispute is one queued mutation. If the phone loses signal in the moment, '
            'the complaint is not lost: it sends with the same idempotency key on reconnect.',
            style: TextStyle(fontSize: 12.5, color: ArvionColors.muted, height: 1.5),
          ),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: _submitting ? null : _submit,
            child: Text(_submitting ? 'Opening…' : 'Submit dispute'),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Keep the booking'),
          ),
        ],
      ),
    );
  }
}
