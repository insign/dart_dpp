import 'dart:io';
import 'package:test/test.dart';

void main() {
  group('Rollback failure test', () {
    late Directory tempDir;
    late File pubspecFile;
    late File changeLogFile;
    late Directory libDir;
    late File pubspec2dartFile;
    late File faultyDartFile;
    late File failingTestFile;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('pub_publish_test_rollback');

      // Initialize a Git repository with mock user credentials
      await Process.run('git', ['init'], workingDirectory: tempDir.path);
      await Process.run('git', ['config', 'user.email', 'test@example.com'], workingDirectory: tempDir.path);
      await Process.run('git', ['config', 'user.name', 'Test User'], workingDirectory: tempDir.path);

      pubspecFile = await File('${tempDir.path}/pubspec.yaml').create();
      await pubspecFile.writeAsString('name: my_package\nversion: 1.0.0\nenvironment:\n  sdk: ">=3.0.0 <4.0.0"\ndependencies:\n  yaml2dart: ^1.5.1');

      changeLogFile = await File('${tempDir.path}/CHANGELOG.md').create();

      libDir = await Directory('${tempDir.path}/lib').create();
      pubspec2dartFile = await File('${libDir.path}/pubspec.dart').create();
      await pubspec2dartFile.writeAsString('// old pubspec2dart contents');

      // Create a faulty dart file to make the `dart format` or `dart analyze` fail
      faultyDartFile = await File('${libDir.path}/faulty.dart').create();
      await faultyDartFile.writeAsString('void main() { print("missing semicolon") }');

      // Create a failing test in test/ directory to ensure tests fail during rollback
      Directory testDir = await Directory('${tempDir.path}/test').create();
      failingTestFile = await File('${testDir.path}/failing_test.dart').create();
      await failingTestFile.writeAsString('''
@Tags(['dpp'])
import 'package:test/test.dart';
void main() {
  test('failing test', () {
    expect(1, 2);
  });
}
''');
    });

    tearDown(() async {
      await tempDir.delete(recursive: true);
    });

    test('rollback tests failure does not prevent pubspec revert', () async {
      // Find the absolute path to the bin/dpp.dart script
      final binPath = '${Directory.current.path}/bin/dpp.dart';

      // Run the tool via Process.run to test CLI behavior and rollback catch mechanism
      final result = await Process.run(
        'dart',
        [
          'run',
          binPath,
          '2.0.0',
          '--no-git',
          '--no-publish'
        ],
        workingDirectory: tempDir.path,
      );

      // We expect the command to fail because `faulty.dart` won't compile
      expect(result.exitCode, isNot(0));

      // Check that pubspec2dart file was reverted
      final pubspec2dartContents = await pubspec2dartFile.readAsString();
      expect(pubspec2dartContents, '// old pubspec2dart contents');

      // Check that pubspec file was reverted
      final pubspecContents = await pubspecFile.readAsString();
      expect(pubspecContents.contains('version: 1.0.0'), isTrue);
    });
  });
}
