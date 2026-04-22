import 'dart:io';
import 'package:test/test.dart';
import 'package:path/path.dart' as p;

void main() {
  test('Rollback logic works even if rollback tests fail', () async {
    // Setup a temporary directory for testing
    final tempDir = Directory.systemTemp.createTempSync('dpp_rollback_test_');

    try {
      // 1. Initialize git
      await Process.run('git', ['init'], workingDirectory: tempDir.path);
      await Process.run('git', ['config', 'user.email', 'test@example.com'],
          workingDirectory: tempDir.path);
      await Process.run('git', ['config', 'user.name', 'Test User'],
          workingDirectory: tempDir.path);

      // 2. Create pubspec.yaml
      final pubspecFile = File(p.join(tempDir.path, 'pubspec.yaml'));
      await pubspecFile.writeAsString('''
name: test_pkg
version: 1.0.0
environment:
  sdk: ">=3.0.0 <4.0.0"
''');

      // 3. Create lib directory and pubspec.dart to verify it gets rolled back too
      final libDir = Directory(p.join(tempDir.path, 'lib'))..createSync();
      final pubspecDartFile = File(p.join(libDir.path, 'pubspec.dart'));
      await pubspecDartFile.writeAsString('// original pubspec.dart content\n');

      // 4. Create a failing test in test/ folder so tests fail during execution and rollback
      final testDir = Directory(p.join(tempDir.path, 'test'))..createSync();
      final failingTestFile = File(p.join(testDir.path, 'failing_test.dart'));
      await failingTestFile.writeAsString('''
import 'dart:io';
void main() {
  print('Failing test!');
  exit(1);
}
''');

      // 5. Commit initial state
      await Process.run('git', ['add', '.'], workingDirectory: tempDir.path);
      await Process.run('git', ['commit', '-m', 'Initial commit'],
          workingDirectory: tempDir.path);

      // 6. Run dpp using absolute path
      final dppPath = p.join(Directory.current.path, 'bin', 'dpp.dart');
      final result = await Process.run(
        'dart',
        [
          dppPath,
          '1.0.1',
          '--pubspec',
          '--pubspec2dart',
          '--no-publish', // Don't try to publish actually
          '--no-git',
          '--tests',
        ],
        workingDirectory: tempDir.path,
      );

      // Verify command failed because of the failing test
      expect(result.exitCode, isNot(0));
      expect(result.stderr.toString(), contains('Command "dart test --exclude-tags dpp" failed'));

      // Verify rollback occurred

      // pubspec.yaml version should be back to 1.0.0
      final updatedPubspec = await pubspecFile.readAsString();
      expect(updatedPubspec, contains('version: 1.0.0'));

      // pubspec.dart should be back to original content
      final updatedPubspecDart = await pubspecDartFile.readAsString();
      expect(updatedPubspecDart, equals('// original pubspec.dart content\n'));

      // Check for rollback log output
      expect(result.stdout.toString(), contains('Rolling back changes to pubspec.yaml...'));
      expect(result.stdout.toString(), contains('Running last dart tests...'));
      expect(result.stdout.toString(), contains('Tests failed during rollback')); // it logs on stdout with [ERROR] or stderr? Let's check stdout since log() prints.
      // pubspec2dart was created before tests, so it should be rolled back!
      expect(result.stdout.toString(), contains('Rolling back changes to pubspec2dart...'));

    } finally {
      // Cleanup
      tempDir.deleteSync(recursive: true);
    }
  });

  test('Rollback deletes pubspec.dart if it was newly created', () async {
    final tempDir = Directory.systemTemp.createTempSync('dpp_rollback_test2_');

    try {
      await Process.run('git', ['init'], workingDirectory: tempDir.path);
      await Process.run('git', ['config', 'user.email', 'test@example.com'],
          workingDirectory: tempDir.path);
      await Process.run('git', ['config', 'user.name', 'Test User'],
          workingDirectory: tempDir.path);

      final pubspecFile = File(p.join(tempDir.path, 'pubspec.yaml'));
      await pubspecFile.writeAsString('''
name: test_pkg
version: 1.0.0
environment:
  sdk: ">=3.0.0 <4.0.0"
''');

      final libDir = Directory(p.join(tempDir.path, 'lib'))..createSync();
      final pubspecDartFile = File(p.join(libDir.path, 'pubspec.dart'));

      // 4. Create a failing test in test/ folder to trigger rollback after pubspec.dart is created
      // Since pubspec.dart is created BEFORE tests, any test failure will trigger rollback
      // of both pubspec.yaml and pubspec.dart.

      await Process.run('git', ['add', '.'], workingDirectory: tempDir.path);
      await Process.run('git', ['commit', '-m', 'Initial commit'],
          workingDirectory: tempDir.path);

      final dppPath = p.join(Directory.current.path, 'bin', 'dpp.dart');
      final result = await Process.run(
        'dart',
        [
          dppPath,
          '1.0.1',
          '--pubspec',
          '--pubspec2dart',
          '--publish', // this will fail without proper setup
          '--no-git',
          '--no-tests', // skip tests so it reaches publish step
        ],
        workingDirectory: tempDir.path,
      );

      // Verify command failed
      expect(result.exitCode, isNot(0));

      // Verify rollback deleted pubspec.dart
      expect(pubspecDartFile.existsSync(), isFalse);

      // Check for rollback log output
      expect(result.stdout.toString(), contains('Rolling back changes to pubspec2dart...'));

    } finally {
      tempDir.deleteSync(recursive: true);
    }
  });
}
