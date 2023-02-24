import 'dart:io';
import 'package:all_exit_codes/all_exit_codes.dart';
import 'package:args/args.dart';
import 'package:dpp/src/dpp.dart';
import 'package:dpp/pubspec.dart' as pubspec;

void main(List<String> args) {
  if (args.isNotEmpty && (args.first == '-v' || args.first == '--version')) {
    showVersion(args);
  }

  final parser = ArgParser()
    ..addCommand('') // No command name means this is the default command.
    ..addFlag('git',
        defaultsTo: true,
        negatable: true,
        help: 'Run git commands: add, commit, tag and push.')
    ..addFlag('any-branch',
        defaultsTo: false,
        negatable: false,
        help: 'Allow to run on any branch.')
    ..addOption('branch',
        help: 'The branch to run on. Default is main or master.',
        valueHelp: 'branch_name')
    ..addFlag('pubspec',
        defaultsTo: true,
        negatable: true,
        help: 'Update the pubspec.yaml file.')
    ..addFlag('pubspec2dart',
        defaultsTo: true,
        negatable: true,
        help: 'Create the pubspec.dart file on the lib/ of the project.')
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
    ..addFlag('version',
        abbr: 'v',
        negatable: false,
        help: 'Show the version of ${pubspec.name}.')
    ..addFlag('help', abbr: 'h', negatable: false, help: 'Show usage help.');

  ArgResults argResults;
  try {
    argResults = parser.parse(args);
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
      argResults.rest.length < 2 ? null : argResults.rest.skip(1).join(' ');

  final dpp = DartPubPublish(
      git: argResults['git'],
      anyBranch: argResults['any-branch'],
      branch: argResults['branch'],
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
  final name = pubspec.name;
  final desc = pubspec.description.split('.').first;
  final version = pubspec.version;

  print('$name - $desc - v$version');
  print('Usage: $name [options] <new version number> [message]');
  print(parser.usage);
  exit(wrongUsage);
}

Never showVersion(args) {
  final version = pubspec.version;

  if (args.first == '-v') {
    print(version);
  } else {
    final name = pubspec.name;
    final desc = pubspec.description.split('.').first;
    print('$name v$version - $desc');
  }

  exit(success);
}
