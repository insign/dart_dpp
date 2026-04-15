import 'dart:io';
import 'package:test/test.dart';
import 'package:path/path.dart' as p;

void main() {
  test('fails fast if branch check fails', () async {
    final tempDir = Directory.systemTemp.createTempSync('fail_fast_test_');

    try {
      await Process.run('git', ['init', '-b', 'main'], workingDirectory: tempDir.path);
      await Process.run('git', ['config', 'user.email', 'test@example.com'], workingDirectory: tempDir.path);
      await Process.run('git', ['config', 'user.name', 'Test User'], workingDirectory: tempDir.path);

      final pubspecFile = File(p.join(tempDir.path, 'pubspec.yaml'));
      await pubspecFile.writeAsString('''
name: test_pkg
version: 1.0.0
environment:
  sdk: ">=3.0.0 <4.0.0"
''');

      await Process.run('git', ['add', '.'], workingDirectory: tempDir.path);
      await Process.run('git', ['commit', '-m', 'Initial commit'], workingDirectory: tempDir.path);
      await Process.run('git', ['checkout', '-b', 'feature-branch'], workingDirectory: tempDir.path);

      final dppPath = p.join(Directory.current.path, 'bin', 'dpp.dart');
      final result = await Process.run(
        'dart',
        [
          dppPath,
          '1.0.1',
          '--no-publish',
          '--git',
          '--no-tests',
          '--no-fix',
          '--no-format',
          '--no-analyze'
        ],
        workingDirectory: tempDir.path,
      );

      print('STDOUT: ${result.stdout}');
      print('STDERR: ${result.stderr}');

      expect(result.exitCode, isNot(0));
      expect(result.stderr.toString(), contains('WrongGitBranchException'));

      final updatedPubspec = await pubspecFile.readAsString();
      expect(updatedPubspec, contains('version: 1.0.0'));
    } finally {
      tempDir.deleteSync(recursive: true);
    }
  });
}
