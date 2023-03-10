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

    test('using version number - change changelog and pubspec', () async {
      final publish = DartPubPublish(
          pubspecFile: pubspecFile.path,
          changeLogFile: changeLogFile.path,
          workingDir: tempDir.path,
          git: false,
          analyze: false,
          format: false,
          fix: false,
          tests: false,
          pubGet: false,
          pubspec: true,
          pubspec2dart: false,
          pubPublish: false);
      await publish.run('2.0.0', message: 'New feature');
      final updatedPubspec = pubspecFile.readAsStringSync();
      final expectedPubspec = 'name: my_package\nversion: 2.0.0\n';
      expect(updatedPubspec, expectedPubspec);

      final updatedChangeLog = changeLogFile.readAsStringSync();
      final expectedChangeLog = '## v2.0.0\n- New feature\n';
      expect(updatedChangeLog, expectedChangeLog);
    });

    test('using alias - change changelog and pubspec', () async {
      final publish = DartPubPublish(
          pubspecFile: pubspecFile.path,
          changeLogFile: changeLogFile.path,
          workingDir: tempDir.path,
          git: false,
          analyze: false,
          format: false,
          fix: false,
          tests: false,
          pubGet: false,
          pubspec: true,
          pubspec2dart: false,
          pubPublish: false);
      await publish.run('major', message: 'New feature');
      final updatedPubspec = pubspecFile.readAsStringSync();
      final expectedPubspec = 'name: my_package\nversion: 2.0.0\n';
      expect(updatedPubspec, expectedPubspec);

      final updatedChangeLog = changeLogFile.readAsStringSync();
      final expectedChangeLog = '## v2.0.0\n- New feature\n';
      expect(updatedChangeLog, expectedChangeLog);
    });
  });
}
