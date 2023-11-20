import 'package:pub_semver/pub_semver.dart';

class PackageVersionAlreadyExistsException implements Exception {
  final String message;

  PackageVersionAlreadyExistsException(Version version)
      : message = 'The version $version already exists. Please choose a different version number.';

  @override
  String toString() => message;
}
