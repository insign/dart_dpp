import 'dart:io';
import 'package:dpp/src/dpp_base.dart';
import 'package:test/test.dart';

void main() {
  group('DartPubPublish - Pubspec Preservation', () {
    late Directory tempDir;
    late File pubspecFile;
    late File changeLogFile;

    setUp(() async {
      tempDir = await Directory.systemTemp
          .createTemp('pub_publish_test_preservation');
      pubspecFile = File('${tempDir.path}/pubspec.yaml');
      changeLogFile = File('${tempDir.path}/CHANGELOG.md');
      await changeLogFile.writeAsString('');
    });

    tearDown(() async {
      await tempDir.delete(recursive: true);
    });

    test('updates version but preserves comments and formatting', () async {
      final initialContent = '''
name: my_package
description: A description.
# This is a comment
version: 1.0.0 # Do not delete me

environment:
  sdk: '>=2.12.0 <3.0.0'
''';
      await pubspecFile.writeAsString(initialContent);

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
          pubPublish: false,
          verbose: false);

      await publish.run('1.0.1', message: 'Fix');

      final updatedContent = pubspecFile.readAsStringSync();

      // Check version update
      expect(updatedContent, contains('version: 1.0.1'));

      // Check comment preservation
      expect(updatedContent, contains('# This is a comment'));

      // Check inline comment preservation
      expect(updatedContent, contains('version: 1.0.1 # Do not delete me'));

      // Check formatting preservation (empty line)
      expect(updatedContent, contains('\nenvironment:'));
    });

    test('updates root version and ignores nested dependency version', () async {
      final initialContent = '''
name: my_package
description: A description.

dependencies:
  some_package:
    version: 1.0.0

version: 1.0.0
''';
      await pubspecFile.writeAsString(initialContent);

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
          pubPublish: false,
          verbose: false);

      await publish.run('2.0.0', message: 'Update root version');

      final updatedContent = pubspecFile.readAsStringSync();

      // Ensure root version is updated
      expect(updatedContent, contains('version: 2.0.0'));
      // Ensure nested version is intact
      expect(updatedContent, contains('    version: 1.0.0'));
    });
  });
}
