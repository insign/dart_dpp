import 'dart:io';
import 'package:dpp/src/dpp.dart';
import 'package:test/test.dart';

void main() {
  group('DartPubPublish empty project tests', () {
    late Directory tempDir;
    late File pubspecFile;
    late File changeLogFile;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('pub_publish_empty_test');

      pubspecFile = await File('${tempDir.path}/pubspec.yaml').create();
      await pubspecFile.writeAsString(
          'name: empty_package\nversion: 1.0.0\nenvironment:\n  sdk: ">=3.0.0 <4.0.0"');

      changeLogFile = await File('${tempDir.path}/CHANGELOG.md').create();

      // Need to add test dependency and test folder to get exit code 79 instead of 65
      await Process.run('dart', ['pub', 'add', '--dev', 'test'],
          workingDirectory: tempDir.path);
      await Directory('${tempDir.path}/test').create();
    });

    tearDown(() async {
      await tempDir.delete(recursive: true);
    });

    test('should succeed even if tests return 79 (no tests matched/found)',
        () async {
      final publish = DartPubPublish(
          pubspecFile: pubspecFile.path,
          changeLogFile: changeLogFile.path,
          workingDir: tempDir.path,
          git: false,
          analyze: false,
          format: false,
          fix: false,
          tests: true, // we want to run tests
          pubGet: true,
          pubspec: true,
          pubspec2dart: false,
          pubPublish: false,
          verbose: false);

      // Should complete without throwing an exception
      await publish.run('2.0.0', message: 'New feature');

      final updatedPubspec = pubspecFile.readAsStringSync();
      expect(updatedPubspec, contains('version: 2.0.0'));
    });
  });
}
