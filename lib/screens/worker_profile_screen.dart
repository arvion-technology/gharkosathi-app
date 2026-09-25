import 'package:flutter/material.dart';

import '../core/models.dart';
import '../router.dart';
import '../theme/arvion_theme.dart';

class WorkerProfileScreen extends StatelessWidget {
  const WorkerProfileScreen({super.key, required this.worker});

  final Worker worker;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Worker profile')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: ArvionColors.gold,
                child: Text(
                  worker.name.split(' ').map((part) => part[0]).take(2).join(),
                  style: const TextStyle(color: Color(0xFF1A1405), fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(worker.name, style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 2),
                    Text('${worker.skill} · Baneshwor', style: const TextStyle(color: ArvionColors.muted)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _badge(
                worker.isVerified ? 'KYC verified' : 'KYC in review',
                worker.isVerified ? ArvionColors.green : ArvionColors.gold,
              ),
              const SizedBox(width: 8),
              _badge('Background checked', ArvionColors.blue),
            ],
          ),
          const SizedBox(height: 22),
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 18),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _stat(worker.rating.toStringAsFixed(1), 'rating'),
                  _stat('${worker.jobsCompleted}', 'jobs'),
                  _stat('98%', 'on time'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text('About', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(
            '${worker.name.split(' ').first} has completed ${worker.jobsCompleted} jobs on GharKo Sathi. '
            'The KYC badge is a state on the worker record, not a label added by the screen: '
            'workers cannot be matched until a reviewer moves it to verified.',
            style: const TextStyle(color: ArvionColors.text2, height: 1.55),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => Navigator.of(context).pushNamed(AppRouter.tracking),
            child: const Text('Message worker'),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: () => Navigator.of(context).pushNamed(AppRouter.wallet),
            child: const Text('View escrow'),
          ),
        ],
      ),
    );
  }

  Widget _badge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }

  Widget _stat(String value, String label) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11, color: ArvionColors.muted)),
      ],
    );
  }
}
