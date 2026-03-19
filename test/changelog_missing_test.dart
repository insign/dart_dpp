import 'dart:io';

import 'package:dpp/src/dpp.dart';
import 'package:test/test.dart';

void main() {
  test('creates CHANGELOG.md when it is missing', () async {
    final tempDir = await Directory.systemTemp.createTemp('pub_publish_test');
    final pubspecFile = await File('${tempDir.path}/pubspec.yaml').create();
    await pubspecFile.writeAsString('name: my_package\nversion: 1.0.0');

    final publish = DartPubPublish(
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
    );

    await publish.run('2.0.0', message: 'New feature');

    final changelogFile = File('${tempDir.path}/CHANGELOG.md');
    expect(changelogFile.existsSync(), isTrue);
    expect(changelogFile.readAsStringSync(), '## v2.0.0\n- New feature\n');

    await tempDir.delete(recursive: true);
  });
}
