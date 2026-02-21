/// Exception thrown when a command fails with a non-zero exit code.
class CommandFailedException implements Exception {
  /// The command that failed.
  final String command;

  /// The arguments passed to the command.
  final List<String> args;

  /// The exit code of the command.
  final int exitCode;

  /// Creates a new instance of [CommandFailedException].
  CommandFailedException(this.command, this.args, this.exitCode);

  @override
  String toString() =>
      'Command "$command ${args.join(' ')}" failed with exit code $exitCode.';
}
