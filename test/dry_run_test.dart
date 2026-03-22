import 'dart:io';
import 'package:dpp/src/dpp_base.dart';
import 'package:test/test.dart';

void main() {
  group('DartPubPublish - Dry Run', () {
    late Directory tempDir;
    late File pubspecFile;
    late File changeLogFile;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('pub_publish_test_dry_run');
      pubspecFile = File('${tempDir.path}/pubspec.yaml');
      await pubspecFile.writeAsString('name: my_package\nversion: 1.0.0');
      changeLogFile = File('${tempDir.path}/CHANGELOG.md');
      await changeLogFile.writeAsString('## v1.0.0\n- Initial release\n');
    });

    tearDown(() async {
      await tempDir.delete(recursive: true);
    });

    test('dry run does not modify files or run commands', () async {
      final publish = DartPubPublish(
          pubspecFile: pubspecFile.path,
          changeLogFile: changeLogFile.path,
          workingDir: tempDir.path,
          git: true,
          analyze: true,
          format: true,
          fix: true,
          tests: true,
          pubGet: true,
          pubspec: true,
          pubspec2dart: true,
          pubPublish: true,
          verbose: true,
          dryRun: true);

      await publish.run('2.0.0', message: 'New feature');

      // Check pubspec.yaml hasn't changed
      final updatedPubspec = pubspecFile.readAsStringSync();
      expect(updatedPubspec, 'name: my_package\nversion: 1.0.0');

      // Check CHANGELOG.md hasn't changed
      final updatedChangeLog = changeLogFile.readAsStringSync();
      expect(updatedChangeLog, '## v1.0.0\n- Initial release\n');

      // Check pubspec.dart hasn't been created
      final pubspecDartFile = File('${tempDir.path}/lib/pubspec.dart');
      expect(pubspecDartFile.existsSync(), false);
    });
  });
}
