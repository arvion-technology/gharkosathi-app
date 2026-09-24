import 'package:flutter/material.dart';

import '../core/mock_data.dart';
import '../core/models.dart';
import '../theme/arvion_theme.dart';

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final job = sampleJob(status: JobStatus.completed);
    return Scaffold(
      appBar: AppBar(title: const Text('Wallet')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('IN ESCROW', style: TextStyle(fontSize: 10.5, letterSpacing: 1.4, color: ArvionColors.muted)),
                  const SizedBox(height: 6),
                  const Text('NPR 3,200', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700, color: ArvionColors.gold)),
                  const SizedBox(height: 4),
                  Text(
                    'Releasable when you confirm job ${job.id} is complete.',
                    style: const TextStyle(fontSize: 12, color: ArvionColors.muted),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      _escrowPill('held', _escrowHeld),
                      const SizedBox(width: 8),
                      _escrowPill('releasable', job.escrow == EscrowState.releasable),
                      const SizedBox(width: 8),
                      _escrowPill('released', job.escrow == EscrowState.released),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text('Activity', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          ...seedWallet.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Card(
                child: ListTile(
                  title: Text(entry.label),
                  subtitle: Text('24 Oct 2026', style: const TextStyle(fontSize: 12, color: ArvionColors.muted)),
                  trailing: Text(
                    '${entry.amount > 0 ? '+' : '−'} NPR ${entry.amount.abs()}',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: entry.amount > 0 ? ArvionColors.green : ArvionColors.text2,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(onPressed: () {}, child: const Text('Add money')),
          const SizedBox(height: 16),
          const Text(
            'Escrow is derived from the job status, not stored as a second balance. That is why the '
            'wallet cannot show “released” while the job still says completed.',
            style: TextStyle(fontSize: 12.5, color: ArvionColors.muted, height: 1.5),
          ),
        ],
      ),
    );
  }

  bool get _escrowHeld => true;

  Widget _escrowPill(String label, bool active) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: active ? const Color(0x1AF5C26B) : Colors.transparent,
        border: Border.all(color: active ? const Color(0x66F5C26B) : ArvionColors.line),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10.5,
          color: active ? ArvionColors.gold : ArvionColors.muted,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
