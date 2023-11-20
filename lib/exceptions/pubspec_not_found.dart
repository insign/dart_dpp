class PubspecNotFound implements Exception {
  final String message;

  PubspecNotFound(String path)
      : message = 'The pubspec file at $path does not exist. Please check the path and try again.';

  @override
  String toString() => message;
}
