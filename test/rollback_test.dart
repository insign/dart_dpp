import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

void main() {
  group('Rollback Integration Test', () {
    late Directory tempDir;
    late File pubspecFile;
    late File changeLogFile;
    late String dppExePath;
    late Directory dppBinDir;

    setUpAll(() async {
      // Compile dpp to an executable
      dppBinDir = await Directory.systemTemp.createTemp('dpp_bin');
      dppExePath = path.join(dppBinDir.path, 'dpp.exe');

      print('Compiling dpp...');
      final compileResult = await Process.run(
        'dart',
        ['compile', 'exe', 'bin/dpp.dart', '-o', dppExePath],
      );

      if (compileResult.exitCode != 0) {
        fail(
            'Failed to compile dpp:\n${compileResult.stdout}\n${compileResult.stderr}');
      }
      print('dpp compiled successfully to $dppExePath');
    });

    tearDownAll(() async {
      await dppBinDir.delete(recursive: true);
    });

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('dpp_rollback_test_proj');

      pubspecFile = File(path.join(tempDir.path, 'pubspec.yaml'));
      await pubspecFile.writeAsString('''
name: test_pkg
version: 1.0.0
environment:
  sdk: '>=2.12.0 <4.0.0'
dev_dependencies:
  test: any
''');

      changeLogFile = File(path.join(tempDir.path, 'CHANGELOG.md'));
      await changeLogFile.writeAsString('# Changelog\n');

      final testDir = Directory(path.join(tempDir.path, 'test'));
      await testDir.create();

      // Create a failing test file
      final failTest = File(path.join(testDir.path, 'fail_test.dart'));
      await failTest.writeAsString('''
import 'package:test/test.dart';
void main() {
  test('fails', () {
    fail('This test is designed to fail');
  });
}
''');

      // Create a passing test file to ensure test runner actually runs
      final passTest = File(path.join(testDir.path, 'pass_test.dart'));
      await passTest.writeAsString('''
import 'package:test/test.dart';
void main() {
  test('passes', () {
    expect(true, isTrue);
  });
}
''');

      // Create a pubspec.lock by running pub get
      // This is needed for running tests
      print('Running pub get in temp project...');
      await Process.run('dart', ['pub', 'get'], workingDirectory: tempDir.path);
    });

    tearDown(() async {
      await tempDir.delete(recursive: true);
    });

    test('should rollback changes when tests fail', () async {
      print('Running dpp in temp project...');
      final result = await Process.run(
        dppExePath,
        [
          'patch',
          '--no-git',
          '--tests', // We want tests to run and fail
          '--no-analyze',
          '--no-fix',
          '--no-format',
          '--no-publish',
          '--no-pubspec2dart', // Simplify
          '--verbose'
        ],
        workingDirectory: tempDir.path,
      );

      print('dpp exit code: ${result.exitCode}');
      print('stdout: ${result.stdout}');
      print('stderr: ${result.stderr}');

      // Verification
      final pubspecContent = await pubspecFile.readAsString();
      // Should be 1.0.0 if rollback happened
      // If rollback failed, it would be 1.0.1
      if (pubspecContent.contains('version: 1.0.1')) {
        print('FAIL: pubspec.yaml was not rolled back.');
      }
      expect(pubspecContent, contains('version: 1.0.0'),
          reason: 'pubspec.yaml should be rolled back');

      final changelogContent = await changeLogFile.readAsString();
      expect(changelogContent, isNot(contains('1.0.1')),
          reason: 'CHANGELOG.md should be rolled back');
    }, timeout: Timeout(Duration(minutes: 5)));
  });
}
