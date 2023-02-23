import 'dart:io';
import 'dart:convert';
import 'package:dpp/exceptions/pubspec_not_found.dart';
import 'package:dpp/exceptions/package_version_already_exists_exception.dart';
import 'package:json2yaml/json2yaml.dart';
import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';

import 'package:yaml2dart/yaml2dart.dart';

// @TODO add publish command

/// A utility class to publish a Dart package to pub.dev.
class DartPubPublish {
  final File _pubspecFile;
  final File _changeLogFile;
  final Directory _workingDir;
  final bool _git;
  final bool _pubspec;
  final bool _pubspec2dart;
  final bool _changelog;
  final bool _tests;
  final bool _fix;
  final bool _format;
  final bool _analyze;
  final bool _verbose;

  /// Creates a new instance of [DartPubPublish].
  ///
  /// [pubspecFile] and [changeLogFile] are the file paths to the pubspec and
  /// changelog files respectively. If not specified, the default values
  /// "pubspec.yaml" and "CHANGELOG.md" will be used, respectively.
  ///
  /// [workingDir] is the working directory to run the commands in. If not specified, the current working directory will be used.
  ///
  /// [git] is a flag indicating whether to run git commands to commit, tag, and push changes. Defaults to true.
  ///
  /// [pubspec] is a flag indicating whether to update the version number in the pubspec file. Defaults to true.
  ///
  /// [pubspec2dart] is a flag indicating whether to generate the `pubspec.dart` file. Defaults to true.
  ///
  /// [changelog] is a flag indicating whether to update the changelog file. Defaults to true.
  ///
  /// [tests] is a flag indicating whether to run tests. Defaults to true.
  ///
  /// [fix] is a flag indicating whether to run `dart fix --apply`. Defaults to true.
  ///
  /// [format] is a flag indicating whether to run `dart format .`. Defaults to true.
  ///
  /// [analyze] is a flag indicating whether to run `dart analyze`. Defaults to true.
  DartPubPublish(
      {String? pubspecFile,
      String? changeLogFile,
      String? workingDir,
      git = true,
      pubspec = true,
      pubspec2dart = true,
      changelog = true,
      tests = true,
      fix = true,
      format = true,
      analyze = true,
      verbose = true})
      : _workingDir =
            workingDir != null ? Directory(workingDir) : Directory.current,
        _pubspecFile = pubspecFile != null
            ? File(pubspecFile)
            : File(path.join(
                workingDir ?? Directory.current.path, 'pubspec.yaml')),
        _changeLogFile = changeLogFile != null
            ? File(changeLogFile)
            : File(path.join(
                workingDir ?? Directory.current.path, 'CHANGELOG.md')),
        _git = git,
        _pubspec = pubspec,
        _pubspec2dart = pubspec2dart,
        _changelog = changelog,
        _tests = tests,
        _fix = fix,
        _format = format,
        _analyze = analyze,
        _verbose = verbose {
    if (!_pubspecFile.existsSync()) {
      throw PubspecNotFound(_pubspecFile.path);
    }
  }

  /// Publishes the package to pub.dev.
  ///
  /// [newVersion] is the new version number for the package.
  ///
  /// [message] is an optional message to be added to the changelog. If not
  /// specified, the changelog will not be updated.
  Future<void> publish(String newVersion, {String? message}) async {
    log('Publishing package to pub.dev...');
    message ??= 'Update version number';
    log('New version: $newVersion');
    log('Message: $message');

    if (_pubspec) {
      // Replace the version number in the pubspec.yaml file
      log('Updating version in pubspec.yaml...');
      final pubspecContents = await _pubspecFile.readAsString();
      final yaml = loadYaml(pubspecContents);
      final oldVersion = yaml['version'] as String;
      if (newVersion == oldVersion) {
        throw PackageVersionAlreadyExistsException(newVersion);
      }
      final updatedYaml = {...yaml, 'version': newVersion};
      final jsonString = json.encode(updatedYaml);
      final jsonMap = json.decode(jsonString);
      final yamlString = json2yaml(jsonMap, yamlStyle: YamlStyle.pubspecYaml);

      _pubspecFile.writeAsStringSync(yamlString);
      log('Updated version in pubspec.yaml from $oldVersion to $newVersion');
    }

    if (_pubspec2dart) {
      // Create the pubspec.dart file
      log('Creating pubspec.dart...');
      final dest = path.join(_workingDir.path, 'pubspec.dart');
      final y2d = Yaml2Dart(_pubspecFile.path, dest);
      await y2d.convert();
    }

    // Run Dart commands to fix, format, analyze, and test the package
    if (_fix) {
      log('Running dart fix --apply...');
      await runCommand('dart', ['fix', '--apply']);
    }
    if (_format) {
      log('Running dart format...');
      await runCommand('dart', ['format', '.']);
    }
    if (_analyze) {
      log('Running dart analyze...');
      await runCommand('dart', ['analyze']);
    }
    if (_tests) {
      log('Running dart tests...');
      await runCommand('dart', ['test']);
    }

    if (_changelog) {
      // Add the new version number and change log message to the head of the CHANGELOG.md file
      log('Updating CHANGELOG.md...');
      final currentContents = await _changeLogFile.readAsString();
      final newContents = '## v$newVersion\n- $message\n$currentContents';
      await _changeLogFile.writeAsString(newContents);
    }

    if (_git) {
      // Commit and push the changes and tag the new version
      log('Committing and pushing changes...');
      await runCommand('git', ['add', '.']);
      await runCommand('git', ['commit', '-m', message]);
      log('Tagging new version...');
      await runCommand('git', ['tag', 'v$newVersion']);
      await runCommand('git', ['push']);
      await runCommand('git', ['push', '--tags']);
    }
  }

  /// Executes the specified [command] with the given list of [args].
  ///
  /// If the [workingDirectory] is not specified, the current directory is used.
  ///
  /// The standard output and standard error of the process are printed to the console as soon as they are received.
  ///
  /// If the process exits with a non-zero exit code, a message indicating the exit code is printed to the console.
  Future<void> runCommand(String command, List<String> args) async {
    final process =
        await Process.start(command, args, workingDirectory: _workingDir.path);
    process.stdout.transform(utf8.decoder).listen((data) {
      // Output the data as soon as it is received
      print(data);
    });
    process.stderr.transform(utf8.decoder).listen((data) {
      // Output the data as soon as it is received
      print(data);
    });
    final exitCode = await process.exitCode;
    if (exitCode != 0) {
      print('Command exited with code $exitCode');
      exit(exitCode);
    }
  }

  void log(String message) {
    if (_verbose) {
      print('[LOG] $message');
    }
  }
}
