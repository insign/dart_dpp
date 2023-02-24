import 'dart:io';
import 'package:all_exit_codes/all_exit_codes.dart';
import 'package:args/args.dart';
import 'package:dpp/dpp.dart';
import '../pubspec.dart' as pubspec;

void main(List<String> arguments) {
  final parser = ArgParser()
    ..addCommand('') // No command name means this is the default command.
    ..addFlag('git',
        defaultsTo: true, negatable: true, help: 'Run or not git commands.')
    ..addFlag('pubspec',
        defaultsTo: true,
        negatable: true,
        help: 'Update the pubspec.yaml file.')
    ..addFlag('pubspec2dart',
        defaultsTo: true,
        negatable: true,
        help: 'Create the pubspec.dart file.')
    ..addFlag('changelog',
        defaultsTo: true, negatable: true, help: 'Update the changelog.')
    ..addFlag('tests',
        defaultsTo: true, negatable: true, help: 'Run dart tests.')
    ..addFlag('fix', defaultsTo: true, negatable: true, help: 'Run dart fix.')
    ..addFlag('format',
        defaultsTo: true, negatable: true, help: 'Run dart format.')
    ..addFlag('analyze',
        defaultsTo: true, negatable: true, help: 'Run dart analyze.')
    ..addFlag('publish',
        defaultsTo: true, negatable: true, help: 'Publish on pub.dev.')
    ..addFlag('verbose',
        defaultsTo: true, negatable: true, help: 'Show verbose output.')
    ..addFlag('version', abbr: 'v', negatable: false, help: 'Show the version.')
    ..addFlag('help', abbr: 'h', negatable: false, help: 'Show usage help.');

  ArgResults argResults;
  try {
    argResults = parser.parse(arguments);
  } on FormatException catch (e) {
    print(e.message);
    showUsage(parser);
  }

  if (argResults['version']) {
    showVersion(parser);
  }

  if (argResults['help'] || argResults.rest.isEmpty) {
    showUsage(parser);
  }
  final String version = argResults.rest.first;

  final String? message =
      argResults.rest[1].isEmpty ? null : argResults.rest.skip(1).join(' ');

  final dpp = DartPubPublish(
      git: argResults['git'],
      pubspec: argResults['pubspec'],
      pubspec2dart: argResults['pubspec2dart'],
      changelog: argResults['changelog'],
      tests: argResults['tests'],
      fix: argResults['fix'],
      format: argResults['format'],
      analyze: argResults['analyze'],
      pubPublish: argResults['publish'],
      verbose: argResults['verbose']);
  dpp.run(version, message: message);
}

Never showUsage(ArgParser parser) {
  print('dpp - A better dart pub publish - v1.1.0');
  print('Usage: dpp [options] <new version number> [message]');
  print(parser.usage);
  exit(wrongUsage);
}

Never showVersion(ArgParser parser) {
  final name = pubspec.name;
  final desc = pubspec.description.split('.').first;
  final version = pubspec.version;

  print('$name - $desc - v$version');
  exit(success);
}
