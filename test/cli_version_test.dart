import 'dart:io';
import 'package:test/test.dart';

void main() {
  group('CLI Version Command', () {
    final dppBin = '${Directory.current.path}/bin/dpp.dart';

    test('returns only version number with -v flag', () async {
      final result = await Process.run('dart', ['run', dppBin, '-v']);
      expect(result.exitCode, equals(0));
      // Deve conter apenas versão do package e nada mais (ex: 2.7.3)
      expect(result.stdout.toString().trim(), matches(RegExp(r'^\d+\.\d+\.\d+$')));
    });

    test('returns only version number with -v even with other flags', () async {
      final result = await Process.run('dart', ['run', dppBin, '--no-git', '-v']);
      expect(result.exitCode, equals(0));
      expect(result.stdout.toString().trim(), matches(RegExp(r'^\d+\.\d+\.\d+$')));
    });

    test('returns full version text with --version flag', () async {
      final result = await Process.run('dart', ['run', dppBin, '--version']);
      expect(result.exitCode, equals(0));
      expect(result.stdout.toString().trim(), startsWith('dpp v'));
      expect(result.stdout.toString().trim(), contains('A better dart'));
    });

    test('returns full version text with --version even with other flags', () async {
      final result = await Process.run('dart', ['run', dppBin, '--no-git', '--version']);
      expect(result.exitCode, equals(0));
      expect(result.stdout.toString().trim(), startsWith('dpp v'));
      expect(result.stdout.toString().trim(), contains('A better dart'));
    });
  });
}
