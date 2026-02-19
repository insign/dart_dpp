import 'dart:io';
import 'package:test/test.dart';
import 'package:path/path.dart' as path;

void main() {
  test('verify rollback happens on failure', () async {
    // 1. Create temp directory for the target project
    final tempDir = await Directory.systemTemp.createTemp('dpp_repro_proj');
    final pubspecFile = File(path.join(tempDir.path, 'pubspec.yaml'));

    // We intentionally avoid dependencies to keep it self-contained and fast.
    // The environment constraint is necessary for analyze to run.
    await pubspecFile.writeAsString('''
name: target_pkg
version: 1.0.0
environment:
  sdk: ">=3.0.0 <4.0.0"
''');

    final changeLogFile = File(path.join(tempDir.path, 'CHANGELOG.md'));
    await changeLogFile.writeAsString('# Changelog\n');

    // Create a file with syntax error to make analyze fail
    final libDir = Directory(path.join(tempDir.path, 'lib'))..createSync();
    File(path.join(libDir.path, 'bad.dart')).writeAsStringSync('void main() { syntax error }');

    // 2. Locate the runner script
    final runnerScriptPath = path.absolute('test/rollback_runner.dart');

    print('Target project at: ${tempDir.path}');
    print('Running dpp from: $runnerScriptPath');

    // 3. Run the runner script
    // We use `dart run` to execute the script.
    final result = await Process.run('dart', ['run', runnerScriptPath, tempDir.path]);

    print('Runner stdout: ${result.stdout}');
    print('Runner stderr: ${result.stderr}');
    print('Runner exit code: ${result.exitCode}');

    // 4. Verify rollback
    final currentPubspec = pubspecFile.readAsStringSync();

    // We expect the version to be 1.0.0 (rolled back).
    // If the bug exists (process exits without rollback), the version will be 1.0.1.
    expect(currentPubspec, contains('version: 1.0.0'), reason: 'Pubspec should be rolled back to 1.0.0 but was not.');

    // Cleanup
    await tempDir.delete(recursive: true);
  });
}
