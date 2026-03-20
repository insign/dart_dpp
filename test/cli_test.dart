import 'dart:io';
import 'package:test/test.dart';
import 'package:dpp/pubspec.dart' as pubspec;

void main() {
  group('CLI Tests', () {
    test('version flag works with other arguments', () async {
      final result = await Process.run('dart', ['run', 'bin/dpp.dart', '--no-git', '--version']);

      expect(result.exitCode, 0);
      expect(result.stdout.toString().trim(), '${pubspec.name} v${pubspec.version} - ${pubspec.description.split('.').first}');
    });

    test('short version flag works with other arguments', () async {
      final result = await Process.run('dart', ['run', 'bin/dpp.dart', '--no-git', '-v']);

      expect(result.exitCode, 0);
      expect(result.stdout.toString().trim(), pubspec.version);
    });

    test('version flag works as first argument', () async {
      final result = await Process.run('dart', ['run', 'bin/dpp.dart', '--version']);

      expect(result.exitCode, 0);
      expect(result.stdout.toString().trim(), '${pubspec.name} v${pubspec.version} - ${pubspec.description.split('.').first}');
    });

    test('short version flag works as first argument', () async {
      final result = await Process.run('dart', ['run', 'bin/dpp.dart', '-v']);

      expect(result.exitCode, 0);
      expect(result.stdout.toString().trim(), pubspec.version);
    });
  });
}
