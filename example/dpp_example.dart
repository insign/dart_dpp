import 'package:dpp/dpp.dart';

void main() {
  final pubPublisher = DartPubPublish(git: false);

  // Publish a new version without updating the changelog
  pubPublisher.run('1.2.0');

  // Publish a new version with a changelog message
  pubPublisher.run('1.3.0', message: 'Added a new feature');

  print('Package published!');
}
