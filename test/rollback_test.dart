import 'dart:io';
import 'package:dpp/src/dpp.dart';
import 'package:test/test.dart';

void main() {
  group('DartPubPublish', () {
    late Directory tempDir;
    late File pubspecFile;
    late File changeLogFile;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('pub_publish_test');
      print('tempDir: ${tempDir.path}');

      pubspecFile = await File('${tempDir.path}/pubspec.yaml').create();
      await pubspecFile.writeAsString('name: my_package\nversion: 1.0.0');
      changeLogFile = await File('${tempDir.path}/CHANGELOG.md').create();
    });

    tearDown(() async {
      await tempDir.delete(recursive: true);
    });

    test('reproduction: fails with exit code but performs rollback', () async {
      final publish = DartPubPublish(
          pubspecFile: pubspecFile.path,
          changeLogFile: changeLogFile.path,
          workingDir: tempDir.path,
          git: true, // Enable git to cause failure (no git repo)
          anyBranch: true,
          analyze: false,
          format: false,
          fix: false,
          tests: false,
          pubGet: false,
          pubspec: true,
          pubspec2dart: false,
          pubPublish: false);

      try {
        await publish.run('2.0.0', message: 'New feature');
        fail('Should have thrown an exception due to git failure');
      } catch (e) {
        print('Caught expected exception: $e');
      }

      final updatedPubspec = pubspecFile.readAsStringSync();
      // Expect rollback to 1.0.0
      final expectedPubspec = 'name: my_package\nversion: 1.0.0';
      expect(updatedPubspec, expectedPubspec);

      // CHANGELOG should be empty as it was created empty
      final updatedChangeLog = changeLogFile.readAsStringSync();
      expect(updatedChangeLog, '');
    });
  });
}
