import 'dart:io';

/// A utility class to publish a Dart package to pub.dev.
class DartPubPublish {
  final String? _pubspecFile;
  final String? _changeLogFile;
  final bool git = true;

  /// Creates a new instance of [DartPubPublish].
  ///
  /// If [pubspecFile] or [changeLogFile] are not specified, the default values
  /// "pubspec.yaml" and "CHANGELOG.md" will be used, respectively.
  DartPubPublish({String? pubspecFile, String? changeLogFile, bool git = true})
      : _pubspecFile = pubspecFile ?? 'pubspec.yaml',
        _changeLogFile = changeLogFile ?? 'CHANGELOG.md';

  /// Publishes the package to pub.dev.
  ///
  /// [newVersion] is the new version number for the package.
  ///
  /// [changeLogMessage] is an optional message to be added to the changelog.
  /// If not specified, the changelog will not be updated.
  ///
  /// If [git] is true (default), runs git commands to commit, tag and push
  void publish(String newVersion, {String? changeLogMessage}) {
    if (changeLogMessage != null) {
      // Add the new version number and change log message to the head of the CHANGELOG.md file
      final currentContents = File(_changeLogFile!).readAsStringSync();
      final newContents =
          '## v$newVersion\n- $changeLogMessage\n$currentContents';
      File(_changeLogFile!).writeAsStringSync(newContents);
    }

    // Replace the version number in the pubspec.yaml file
    final pubspec = File(_pubspecFile!).readAsStringSync();
    final newPubspec =
        pubspec.replaceAll(RegExp(r'^version: .*$'), 'version: $newVersion');
    File(_pubspecFile!).writeAsStringSync(newPubspec);

    // Run Dart commands to fix, format, analyze, and test the package
    Process.runSync('dart', ['fix', '--apply']);
    Process.runSync('dart', ['format', '.']);
    Process.runSync('dart', ['analyze']);
    Process.runSync('dart', ['test']);

    if (git) {
      // Commit and push the changes and tag the new version
      Process.runSync('git', ['add', '.']);
      Process.runSync(
          'git', ['commit', '-m', changeLogMessage ?? 'Update version number']);
      Process.runSync('git', ['tag', 'v$newVersion']);
      Process.runSync('git', ['push']);
      Process.runSync('git', ['push', '--tags']);
    }
  }
}
