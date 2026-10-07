import 'dart:io';

/// Tiny test harness.
///
/// The sample avoids `package:test` on purpose: `dart test/...` runs with no
/// `pub get` and no network, which is what makes the pure-Dart logic layer easy
/// to verify from a fresh clone. The assertions are deliberately plain.
class TestSuite {
  TestSuite(this.name);

  final String name;
  var passed = 0;
  final List<String> failures = [];

  void test(String label, void Function() body) {
    try {
      body();
      passed += 1;
    } catch (error) {
      failures.add('$label: $error');
    }
  }

  Future<void> testAsync(String label, Future<void> Function() body) async {
    try {
      await body();
      passed += 1;
    } catch (error) {
      failures.add('$label: $error');
    }
  }

  void expect(bool condition, String message) {
    if (!condition) throw message;
  }

  void equals(Object? actual, Object? expected, String message) {
    if (actual != expected) throw '$message — expected $expected, got $actual';
  }

  void run() {
    stdout.writeln('$name: $passed passed, ${failures.length} failed');
    for (final failure in failures) {
      stdout.writeln('  FAIL $failure');
    }
    if (failures.isNotEmpty) exitCode = 1;
  }
}
