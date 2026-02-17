import 'dart:io';
import 'package:test/test.dart';
import 'package:path/path.dart' as p;

void main() {
  test('verify dpp rollback works when command fails', () async {
    final tempDir = Directory.systemTemp.createTempSync('dpp_rollback_test');
    final helperFile = File(
        p.join(Directory.current.path, 'test', 'temp_rollback_helper.dart'));

    addTearDown(() {
      if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
      if (helperFile.existsSync()) helperFile.deleteSync();
    });

    print('Temp dir: ${tempDir.path}');

    // Setup initial state
    File(p.join(tempDir.path, 'pubspec.yaml')).writeAsStringSync('''
name: test_pkg
version: 1.0.0
environment:
  sdk: '>=2.12.0 <4.0.0'
''');
    File(p.join(tempDir.path, 'CHANGELOG.md'))
        .writeAsStringSync('# Changelog\n');
    Directory(p.join(tempDir.path, 'lib')).createSync();
    File(p.join(tempDir.path, 'lib', 'bad.dart'))
        .writeAsStringSync('This is a syntax error');

    // Create the helper script inside test/ folder to access package:dpp
    helperFile.writeAsStringSync(r'''
import 'dart:io';
import 'package:dpp/src/dpp.dart';

void main(List<String> args) async {
  final workingDir = args[0];
  final dpp = DartPubPublish(
    workingDir: workingDir,
    pubGet: false,
    git: false,
    analyze: true,
    tests: false,
    fix: false,
    format: false,
    pubspec2dart: false,
    pubPublish: false,
    verbose: true,
  );

  print('Running dpp...');
  try {
    await dpp.run('1.0.1');
    print('dpp finished normally');
  } catch (e) {
    print('dpp threw exception: $e');
  }
}
''');

    // Run the helper script
    final process = await Process.start(
      'dart',
      [helperFile.path, tempDir.path],
      workingDirectory: Directory.current.path,
    );

    // Capture output for debugging
    process.stdout
        .transform(SystemEncoding().decoder)
        .listen((data) => print('STDOUT: $data'));
    process.stderr
        .transform(SystemEncoding().decoder)
        .listen((data) => print('STDERR: $data'));

    final exitCode = await process.exitCode;
    print('Process exited with $exitCode');

    // Check pubspec content
    final pubspecContent =
        File(p.join(tempDir.path, 'pubspec.yaml')).readAsStringSync();

    // We expect the bug to be fixed, so we expect version 1.0.0 (rolled back)
    if (pubspecContent.contains('version: 1.0.0')) {
      print('Fix CONFIRMED: version is 1.0.0 (rolled back)');
    } else {
      print('Fix NOT CONFIRMED: version is 1.0.1 (not rolled back)');
    }

    // This assertion confirms the fix is working.
    expect(pubspecContent, contains('version: 1.0.0'),
        reason: 'Rollback should have occurred after command failure');
  });
}
