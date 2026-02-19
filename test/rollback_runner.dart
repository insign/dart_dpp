import 'dart:io';
import 'package:dpp/src/dpp.dart';

void main(List<String> args) async {
  if (args.isEmpty) {
    print('Error: No target path provided');
    exit(1);
  }
  final targetPath = args[0];
  print('Running dpp on $targetPath');

  // Create publisher instance
  final publisher = DartPubPublish(
    workingDir: targetPath,
    pubGet: false, // Skip pub get to avoid network/time overhead
    analyze: true, // This should fail due to syntax error
    tests: false,
    format: false,
    fix: false,
    git: false,
    pubPublish: false,
    pubspec2dart: false,
    verbose: true
  );

  try {
    // Attempt to publish version 1.0.1
    // This will update pubspec.yaml to 1.0.1
    // Then run analyze, which fails.
    // If rollback works, pubspec.yaml should revert to 1.0.0.
    // If rollback fails (due to exit()), pubspec.yaml remains at 1.0.1.
    await publisher.run('1.0.1');
  } catch (e) {
    print('Caught exception: $e');
    // We expect exception but also exit(code).
    // If exit() is called inside run(), this catch block might not be reached fully or process terminates.
  }
}
