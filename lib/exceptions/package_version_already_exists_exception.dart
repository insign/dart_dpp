class PackageVersionAlreadyExistsException implements Exception {
  final String message;

  PackageVersionAlreadyExistsException(String version)
      : message =
            'The version $version already exists. Please choose a different version number.';

  @override
  String toString() => message;
}
