import 'dart:io';
import 'package:all_exit_codes/all_exit_codes.dart';
import 'package:args/args.dart';
import 'package:dpp/dpp.dart';

void main(List<String> arguments) {
  final parser = ArgParser()
    ..addCommand('') // No command name means this is the default command.
    ..addFlag('git',
        defaultsTo: true, negatable: true, help: 'Run or not git commands.')
    ..addOption('message',
        abbr: 'm', help: 'Add a message to the changelog/git commit.')
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
    ..addFlag('help', abbr: 'h', negatable: false, help: 'Show usage help.');

  ArgResults argResults;
  try {
    argResults = parser.parse(arguments);
  } on FormatException catch (e) {
    print(e.message);
    showUsage(parser);
  }

  if (argResults['help'] || argResults.rest.isEmpty) {
    showUsage(parser);
  }
  final version = argResults.rest.first;

  final dpp = DartPubPublish(
      git: argResults['git'],
      pubspec: argResults['pubspec'],
      pubspec2dart: argResults['pubspec2dart'],
      changelog: argResults['changelog'],
      tests: argResults['tests'],
      fix: argResults['fix'],
      format: argResults['format'],
      analyze: argResults['analyze']);

  dpp.publish(version, message: argResults['message']);
}

Never showUsage(ArgParser parser) {
  print(parser.usage);
  exit(wrongUsage);
}
