import 'package:pub_semver/pub_semver.dart';

class PackageVersionLowerException implements Exception {
  final String message;

  PackageVersionLowerException(Version version, Version currentVersion)
      : message =
            'The version $version is lower than the current version $currentVersion. Please choose a higher version number.';

  @override
  String toString() => message;
}
