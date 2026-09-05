import 'dart:convert';

/// Offline-first mutation queue.
///
/// The queue is intentionally small: ordered operations, an idempotency key per
/// operation, stop-on-first-failure, exponential backoff, and JSON persistence so
/// an operation survives the process being killed. Flutter is not imported here,
/// which lets the queue's ordering rules be tested in plain Dart.

class OfflineOperation {
  OfflineOperation({
    required this.key,
    required this.type,
    this.payload = const {},
    this.attempts = 0,
    this.createdAt,
  });

  final String key;
  final String type;
  final Map<String, dynamic> payload;
  int attempts;
  final DateTime? createdAt;

  OfflineOperation copyWith({int? attempts}) => OfflineOperation(
        key: key,
        type: type,
        payload: payload,
        attempts: attempts ?? this.attempts,
        createdAt: createdAt,
      );

  Map<String, dynamic> toJson() => {
        'key': key,
        'type': type,
        'payload': payload,
        'attempts': attempts,
        'createdAt': (createdAt ?? DateTime.fromMillisecondsSinceEpoch(0)).toIso8601String(),
      };

  static OfflineOperation fromJson(Map<String, dynamic> json) => OfflineOperation(
        key: json['key'] as String,
        type: json['type'] as String,
        payload: Map<String, dynamic>.from(json['payload'] as Map? ?? const {}),
        attempts: json['attempts'] as int? ?? 0,
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
      );
}

class FlushResult {
  const FlushResult({
    required this.sent,
    required this.failed,
    required this.remaining,
    required this.retryIn,
    required this.exhausted,
  });

  final int sent;
  final List<OfflineOperation> failed;
  final int remaining;
  final Duration retryIn;
  final bool exhausted;
}

class OfflineQueue {
  OfflineQueue({List<OfflineOperation> initial = const []}) : _operations = [...initial];

  static const int maxAttempts = 5;
  static const Duration baseBackoff = Duration(seconds: 1);
  static const Duration maxBackoff = Duration(seconds: 30);

  final List<OfflineOperation> _operations;
  final Set<String> _keys = {};

  int get size => _operations.length;
  bool get isDrained => _operations.isEmpty;
  OfflineOperation? get first => _operations.isEmpty ? null : _operations.first;
  List<OfflineOperation> get pending => List.unmodifiable(_operations);

  static Duration backoffFor(int attempts) {
    if (attempts <= 0) return Duration.zero;
    final millis = baseBackoff.inMilliseconds * (1 << (attempts - 1));
    final capped = millis > maxBackoff.inMilliseconds ? maxBackoff.inMilliseconds : millis;
    return Duration(milliseconds: capped);
  }

  bool enqueue({
    required String key,
    required String type,
    Map<String, dynamic> payload = const {},
    DateTime? createdAt,
  }) {
    if (_keys.contains(key)) return false;
    _keys.add(key);
    _operations.add(OfflineOperation(key: key, type: type, payload: payload, createdAt: createdAt));
    return true;
  }

  bool discard(String key) {
    final index = _operations.indexWhere((operation) => operation.key == key);
    if (index == -1) return false;
    _keys.remove(key);
    _operations.removeAt(index);
    return true;
  }

  /// Attempts queued work in order. The handler resolves true on success. The
  /// first failure stops the flush: a later job update must never overtake an
  /// earlier one, even if the server would accept it.
  Future<FlushResult> flush(Future<bool> Function(OfflineOperation) handler) async {
    var sent = 0;
    final failed = <OfflineOperation>[];
    while (_operations.isNotEmpty) {
      final operation = _operations.first;
      operation.attempts += 1;
      var ok = false;
      try {
        ok = await handler(operation);
      } catch (_) {
        ok = false;
      }
      if (ok) {
        _operations.removeAt(0);
        _keys.remove(operation.key);
        sent += 1;
      } else {
        failed.add(operation);
        break;
      }
    }
    final remaining = _operations.length;
    final retryIn = remaining == 0 ? Duration.zero : backoffFor(_operations.first.attempts);
    final exhausted = remaining > 0 && _operations.first.attempts >= maxAttempts;
    return FlushResult(
      sent: sent,
      failed: failed,
      remaining: remaining,
      retryIn: retryIn,
      exhausted: exhausted,
    );
  }

  String serialize() => jsonEncode(_operations.map((operation) => operation.toJson()).toList());

  int restore(String serialized) {
    final decoded = jsonDecode(serialized);
    if (decoded is! List) throw const FormatException('serialized queue must be a list');
    _operations.clear();
    _keys.clear();
    for (final item in decoded) {
      final operation = OfflineOperation.fromJson(Map<String, dynamic>.from(item as Map));
      _operations.add(operation);
      _keys.add(operation.key);
    }
    return _operations.length;
  }
}
