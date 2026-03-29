import 'dart:io';
import 'package:dpp/src/dpp.dart';
import 'package:test/test.dart';

void main() {
  group('Rollback behavior', () {
    late Directory tempDir;
    late File pubspecFile;
    late File changeLogFile;
    late Directory libDir;
    late File dartFile;

    setUp(() async {
      tempDir =
          await Directory.systemTemp.createTemp('pub_publish_test_rollback');

      pubspecFile = await File('${tempDir.path}/pubspec.yaml').create();
      await pubspecFile.writeAsString(
          'name: my_package\nversion: 1.0.0\nenvironment:\n  sdk: ">=3.0.0 <4.0.0"\n');

      changeLogFile = await File('${tempDir.path}/CHANGELOG.md').create();
      await changeLogFile.writeAsString('## v1.0.0\n- Initial release\n');

      libDir = await Directory('${tempDir.path}/lib').create();

      // We create a broken dart file so that dart format or analyze will fail, triggering a rollback
      dartFile = await File('${libDir.path}/broken.dart').create();
      await dartFile.writeAsString(
          'void main() { print("hello" }'); // Missing closing parenthesis
    });

    tearDown(() async {
      await tempDir.delete(recursive: true);
    });

    test('rolls back pubspec, changelog and deletes pubspec.dart on failure',
        () async {
      final publish = DartPubPublish(
          pubspecFile: pubspecFile.path,
          changeLogFile: changeLogFile.path,
          workingDir: tempDir.path,
          git: false,
          analyze: true, // Analyze will fail on the broken dart file
          format: false,
          fix: false,
          tests: false,
          pubGet: false,
          pubspec: true,
          pubspec2dart: true,
          pubPublish: false,
          verbose: false);

      try {
        await publish.run('2.0.0', message: 'New feature');
        fail('Should have thrown an exception');
      } catch (e) {
        // Expected an exception
      }

      final updatedPubspec = pubspecFile.readAsStringSync();
      final expectedPubspec =
          'name: my_package\nversion: 1.0.0\nenvironment:\n  sdk: ">=3.0.0 <4.0.0"\n';
      expect(updatedPubspec, expectedPubspec,
          reason: 'Pubspec should be rolled back');

      final updatedChangeLog = changeLogFile.readAsStringSync();
      final expectedChangeLog = '## v1.0.0\n- Initial release\n';
      expect(updatedChangeLog, expectedChangeLog,
          reason: 'Changelog should be rolled back');

      final pubspecDartFile = File('${libDir.path}/pubspec.dart');
      expect(pubspecDartFile.existsSync(), isFalse,
          reason: 'pubspec.dart should have been deleted');
    });
  });
}
