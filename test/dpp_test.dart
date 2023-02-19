import 'dart:io';
import 'package:dpp/dpp.dart';
import 'package:test/test.dart';

void main() {
  group('DartPubPublish', () {
    late Directory tempDir;
    late File pubspecFile;
    late File changeLogFile;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('pub_publish_test');
      pubspecFile = await File('${tempDir.path}/pubspec.yaml').create();
      await pubspecFile.writeAsString('name: my_package\nversion: 1.0.0');
      changeLogFile = await File('${tempDir.path}/CHANGELOG.md').create();
    });

    tearDown(() async {
      await tempDir.delete(recursive: true);
    });

    test('publish', () {
      final publish = DartPubPublish(
        pubspecFile: pubspecFile.path,
        changeLogFile: changeLogFile.path,
        git: false,
      );
      publish.publish('2.0.0', changeLogMessage: 'New feature');
      final updatedPubspec = pubspecFile.readAsStringSync();
      final expectedPubspec = 'name: my_package\nversion: 2.0.0';
      expect(updatedPubspec, expectedPubspec);

      final updatedChangeLog = changeLogFile.readAsStringSync();
      final expectedChangeLog = '## v2.0.0\n- New feature\n';
      expect(updatedChangeLog, expectedChangeLog);
    });
  });
}
