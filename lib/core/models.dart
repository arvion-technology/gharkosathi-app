import 'dart:math' as math;

/// Domain models for GharKo Sathi. No Flutter imports in this layer, which keeps
/// the state machine and queue testable with `dart test/...` alone.

enum JobStatus {
  draft, requested, matching, matched, enRoute, inProgress,
  completed, paid, disputed, refunded, cancelled, closed,
}

extension JobStatusWire on JobStatus {
  String get wire => name;

  static JobStatus parse(String value) {
    return JobStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => throw ArgumentError('unknown job status: $value'),
    );
  }
}

enum KycState { notStarted, documentsUploaded, inReview, verified, rejected }

enum EscrowState { held, releasable, released, frozen }

class Service {
  const Service({
    required this.id,
    required this.name,
    required this.category,
    required this.basePrice,
    required this.durationMinutes,
  });

  final String id;
  final String name;
  final String category;
  final int basePrice;
  final int durationMinutes;
}

class Worker {
  const Worker({
    required this.id,
    required this.name,
    required this.skill,
    required this.rating,
    required this.jobsCompleted,
    required this.kyc,
  });

  final String id;
  final String name;
  final String skill;
  final double rating;
  final int jobsCompleted;
  final KycState kyc;

  bool get isVerified => kyc == KycState.verified;
}

class JobEvent {
  const JobEvent({required this.from, required this.to, required this.at, this.note = ''});

  final JobStatus from;
  final JobStatus to;
  final DateTime at;
  final String note;

  Map<String, dynamic> toJson() => {
        'from': from.wire,
        'to': to.wire,
        'at': at.toIso8601String(),
        'note': note,
      };
}

class Job {
  const Job({
    required this.id,
    required this.serviceId,
    required this.customerId,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.workerId,
    this.address = '',
    this.escrowHeld = true,
    this.proofUploaded = false,
    this.history = const [],
  });

  final String id;
  final String serviceId;
  final String customerId;
  final String? workerId;
  final String address;
  final JobStatus status;
  final bool escrowHeld;
  final bool proofUploaded;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<JobEvent> history;

  Job copyWith({
    String? workerId,
    JobStatus? status,
    bool? proofUploaded,
    DateTime? updatedAt,
    List<JobEvent>? history,
  }) {
    return Job(
      id: id,
      serviceId: serviceId,
      customerId: customerId,
      workerId: workerId ?? this.workerId,
      address: address,
      status: status ?? this.status,
      escrowHeld: escrowHeld,
      proofUploaded: proofUploaded ?? this.proofUploaded,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      history: history ?? this.history,
    );
  }

  bool get isTerminal => status == JobStatus.closed;

  /// The wallet reads this instead of storing a second balance, so the two
  /// screens cannot disagree about money.
  EscrowState get escrow {
    switch (status) {
      case JobStatus.disputed:
      case JobStatus.refunded:
        return EscrowState.frozen;
      case JobStatus.paid:
      case JobStatus.closed:
        return EscrowState.released;
      case JobStatus.completed:
        return EscrowState.releasable;
      default:
        return EscrowState.held;
    }
  }
}

class WalletEntry {
  const WalletEntry({
    required this.id,
    required this.label,
    required this.amount,
    required this.createdAt,
  });

  final String id;
  final String label;
  final int amount; // NPR, whole rupees
  final DateTime createdAt;
}

class Dispute {
  const Dispute({required this.jobId, required this.reason, required this.openedAt, this.photoCount = 0});

  final String jobId;
  final String reason;
  final DateTime openedAt;
  final int photoCount;

  bool get isValid => reason.trim().length >= 10;
}

class Quote {
  const Quote({required this.serviceId, required this.amount, required this.visitFee});

  final String serviceId;
  final int amount;
  final int visitFee;

  /// There is no hidden fee: the estimate the booking screen shows is the sum of
  /// the two fields, and the invoice renders the same two lines.
  int get total => amount + visitFee;

  String get formatted => 'NPR ${_thousands(total)}';

  static String _thousands(int value) {
    final digits = value.abs().toString();
    final buffer = StringBuffer();
    for (var index = 0; index < digits.length; index++) {
      final remaining = digits.length - index;
      if (index > 0 && remaining % 3 == 0) buffer.write(',');
      buffer.write(digits[index]);
    }
    return '${value < 0 ? '-' : ''}$buffer';
  }
}

/// Small helper used by the tracking screen to decide whether a new worker is a
/// better match than the current one. Kept here because the rule is a domain
/// rule, not a UI rule.
Worker? bestMatch(Iterable<Worker> workers, String skill) {
  Worker? best;
  var bestScore = -1.0;
  for (final worker in workers) {
    if (!worker.isVerified || worker.skill != skill) continue;
    final score = worker.rating * 20 + math.min(worker.jobsCompleted, 500) * 0.02;
    if (score > bestScore) {
      bestScore = score;
      best = worker;
    }
  }
  return best;
}
