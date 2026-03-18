import 'dart:io';
import 'dart:convert';
import 'package:all_exit_codes/all_exit_codes.dart';
import 'package:dpp/exceptions/command_failed_exception.dart';
import 'package:dpp/exceptions/package_version_lower_exception.dart';
import 'package:dpp/exceptions/pubspec_not_found.dart';
import 'package:dpp/exceptions/package_version_already_exists_exception.dart';
import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';

import 'package:pub_semver/pub_semver.dart';

import 'package:yaml2dart/yaml2dart.dart';

/// A utility class to publish a Dart package to pub.dev.
class DartPubPublish {
  /// The file path to the pubspec file.
  final File _pubspecFile;

  /// The file path to the changelog file.
  final File _changeLogFile;

  /// The working directory to run the commands in.
  final Directory _workingDir;

  /// A flag indicating whether to run the `dart pub get` command.
  final bool _get;

  /// A flag indicating whether to run git commands to commit, tag, and push changes.
  final bool _git;

  /// A flag indicating whether to run git commands on any branch.
  final bool _anyBranch;

  /// A flag indicating whether to only run git commands on the specified branch.
  final String? _branch;

  /// A flag indicating whether to update the version number in the pubspec file.
  final bool _pubspec;

  /// A flag indicating whether to generate the `pubspec.dart` file.
  final bool _pubspec2dart;

  /// A flag indicating whether to update the changelog file.
  final bool _changelog;

  /// A flag indicating whether to run tests.
  final bool _tests;

  /// A flag indicating whether to run `dart fix --apply`.
  final bool _fix;

  /// A flag indicating whether to run `dart format .`.
  final bool _format;

  /// A flag indicating whether to run `dart analyze`.
  final bool _analyze;

  /// A flag indicating whether to publish the package to pub.dev.
  final bool _publish;

  /// A flag indicating whether to print log messages to the console.
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
  ///
  /// [pubPublish] is a flag indicating whether to publish the package to pub.dev. Defaults to true.
  ///
  /// [verbose] is a flag indicating whether to print log messages to the console. Defaults to true.
  /// Throws a [PubspecNotFound] exception if the pubspec file does not exist.
  DartPubPublish(
      {String? pubspecFile,
      String? changeLogFile,
      String? workingDir,
      pubGet = true,
      git = true,
      anyBranch = false,
      branch,
      pubspec = true,
      pubspec2dart = true,
      changelog = true,
      tests = true,
      fix = true,
      format = true,
      analyze = true,
      pubPublish = true,
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
        _get = pubGet,
        _git = git,
        _anyBranch = anyBranch,
        _branch = branch,
        _pubspec = pubspec,
        _pubspec2dart = pubspec2dart,
        _changelog = changelog,
        _tests = tests,
        _fix = fix,
        _format = format,
        _analyze = analyze,
        _publish = pubPublish,
        _verbose = verbose {
    if (!_pubspecFile.existsSync()) {
      throw PubspecNotFound(_pubspecFile.path);
    }
  }

  /// Runs a series of commands to publish a Dart package to pub.dev.
  ///
  /// [version] is mandatory and must be a valid semantic version number
  /// but [version] can patch, minor or major too,
  /// which is automatically detected and incremented.
  /// An optional message can be provided for the change log (and git commit)
  /// by setting the [message] parameter.
  ///
  /// If any of the commands fail, the changes made to the pubspec.yaml and CHANGELOG.md files
  /// will be rolled back.
  ///
  /// The following optional boolean parameters control which commands are run:
  /// - [_pubspec] Whether to update the version number in the pubspec.yaml file. Default is true.
  /// - [_pubspec2dart] Whether to create the pubspec.dart file in lib directory. Default is true.
  /// - [_get] Whether to run dart pub get. Default is true.
  /// - [_fix] Whether to run dart fix --apply. Default is true.
  /// - [_format] Whether to run dart format .. Default is true.
  /// - [_analyze] Whether to run dart analyze. Default is true.
  /// - [_tests] Whether to run dart test. Default is true.
  /// - [_changelog] Whether to update the CHANGELOG.md file. Default is true.
  /// - [_publish] Whether to publish the package to pub.dev. Default is true.
  /// - [_git] Whether to commit and push the changes and tag the new version. Default is true.
  ///
  /// Throws a [PackageVersionAlreadyExistsException] if the package version already exists on pub.dev.
  Future<void> run(String version,
      {String message = 'Update version number'}) async {
    String? oldChangeLogContents;
    String oldPubspecContents = _pubspecFile.readAsStringSync();
    File pubspec2dartFile =
        File(path.join(_workingDir.path, 'lib', 'pubspec.dart'));
    String? oldPubspec2dartContents =
        _pubspec2dart && pubspec2dartFile.existsSync()
            ? pubspec2dartFile.readAsStringSync()
            : null;
    final yaml = loadYaml(oldPubspecContents);
    final oldVersion = Version.parse(yaml['version']);
    Version newVersion;
    bool changedChangeLog = false,
        changedPubspec = false,
        changedPubspec2dart = false;

    try {
      newVersion = Version.parse(version);
    } on FormatException {
      if (version == 'patch') {
        newVersion = oldVersion.nextPatch;
      } else if (version == 'minor') {
        newVersion = oldVersion.nextMinor;
      } else if (version == 'major') {
        newVersion = oldVersion.nextMajor;
      } else {
        throw FormatException('Invalid version: $version');
      }
    }

    if (newVersion == oldVersion) {
      throw PackageVersionAlreadyExistsException(newVersion);
    }
    if (newVersion < oldVersion) {
      throw PackageVersionLowerException(newVersion, oldVersion);
    }

    log('Publishing package to pub.dev...');
    log('Old version: $oldVersion');
    log('New version: $newVersion');
    log('Message: $message');
    log('Working directory: ${_workingDir.path}');

    if (_pubspec) {
      // Replace the version number in the pubspec.yaml file
      log('Updating version in pubspec.yaml...');

      final updatedPubspecContents = oldPubspecContents.replaceFirst(
        RegExp(r'^version\s*:.*$', multiLine: true),
        'version: $newVersion',
      );

      _pubspecFile.writeAsStringSync(updatedPubspecContents);
      log('Updated version in pubspec.yaml from $oldVersion to $newVersion');
      changedPubspec = true;
    }
    try {
      if (_get) {
        // Run pub get
        log('Running dart pub get...');
        await runCommand('dart', ['pub', 'get']);
      }

      if (_analyze) {
        log('Running dart analyze...');
        await runCommand('dart', ['analyze']);
      }
      if (_tests) {
        log('Running dart tests...');
        await runCommand('dart', ['test', '--exclude-tags', 'dpp']);
      }

      if (_pubspec2dart) {
        // Create the pubspec.dart file
        log('Creating pubspec.dart... inside lib folder');
        final libDir = Directory(path.join(_workingDir.path, 'lib'));
        if (!libDir.existsSync()) {
          log('No lib folder found, ignoring pubspec2dart option', error: true);
        } else {
          final dest = path.join(_workingDir.path, 'lib', 'pubspec.dart');
          final y2d = Yaml2Dart(_pubspecFile.path, dest);
          await y2d.convert();
          changedPubspec2dart = true;
        }
      }

      if (_fix) {
        log('Running dart fix --apply...');
        await runCommand('dart', ['fix', '--apply']);
      }
      if (_format) {
        log('Running dart format...');
        await runCommand('dart', ['format', '.', '--line-length', '120']);
      }

      if (_changelog) {
        // Add the new version number and change log message to the head of the CHANGELOG.md file
        log('Updating CHANGELOG.md...');
        oldChangeLogContents = await _changeLogFile.readAsString();
        final newContents =
            '## v$newVersion\n- $message\n$oldChangeLogContents';
        await _changeLogFile.writeAsString(newContents);
        changedChangeLog = true;
      }

      if (_publish) {
        // Publish the package to pub.dev
        log('Publishing package to pub.dev...');
        await runCommand('dart', ['pub', 'publish', '--force']);
      }
    } on Exception catch (e) {
      // Rollback the changes to the pubspec.yaml file
      log(e.toString(), error: true);

      if (_pubspec && changedPubspec) {
        log('Rolling back changes to pubspec.yaml...');
        _pubspecFile.writeAsStringSync(oldPubspecContents);
      }

      // Rollback the changes to the CHANGELOG.md file
      if (_changelog && oldChangeLogContents != null && changedChangeLog) {
        log('Rolling back changes to CHANGELOG.md...');
        _changeLogFile.writeAsStringSync(oldChangeLogContents);
      }

      if (_tests) {
        log('Running last dart tests...');
        await runCommand('dart', ['test', '--tags', 'dpp']);
      }

      // Rollback the changes to the pubspec2dart file
      if (_pubspec2dart &&
          oldPubspec2dartContents != null &&
          changedPubspec2dart) {
        log('Rolling back changes to pubspec2dart...');
        pubspec2dartFile.writeAsStringSync(oldPubspec2dartContents);
      }

      rethrow;
    }
    if (_git) {
      final onBranch = await isBranch(_branch);
      if (!_anyBranch && !onBranch) {
        log('Not on $_branch branch, skipping git commands', error: true);
      } else {
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
  }

  /// Executes the specified [command] with the given list of [args].
  ///
  /// If the [workingDirectory] is not specified, the current directory is used.
  ///
  /// The standard output and standard error of the process are printed to the console as soon as they are received.
  ///
  /// If the process exits with a non-zero exit code, a message indicating the exit code is printed to the console and
  /// the program is terminated with that exit code.
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
      throw CommandFailedException(command, args, exitCode);
    }
  }

  /// Logs a message to the console, with the option to mark it as an error.
  ///
  /// If [_verbose] is true, the message will be printed to the console. If
  /// error is true, the message will be prefixed with [ERROR]. Otherwise,
  /// it will be prefixed with [LOG].
  ///
  /// If [_verbose] is false, this method does nothing.
  void log(String message, {bool error = false}) {
    if (_verbose) {
      if (error) {
        print('[ERROR] $message');
      } else {
        print('[LOG] $message');
      }
    }
  }

  Future<bool> isBranch(String? branch) async {
    final ProcessResult result = await Process.run(
        'git', ['branch', '--show-current'],
        workingDirectory: _workingDir.path);

    final currentBranchName = result.stdout.trim();

    if (branch != null) {
      return currentBranchName == branch;
    }

    return currentBranchName == 'main' || currentBranchName == 'master';
  }
}
