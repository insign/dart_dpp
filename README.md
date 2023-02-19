A better dart pub publish, by running tests, fixes, lint, update CHANGELOG file and git commands.

## Getting started

```dart
dart pub add dpp
```
## Usage

```dart
void main() {
  final pubPublisher = DartPubPublish(git: false);

  // Publish a new version without updating the changelog
  pubPublisher.publish('1.2.0');

  // Publish a new version with a changelog message
  pubPublisher.publish('1.3.0', changeLogMessage: 'Added a new feature');

  print('Package published!');
}
```

## LICENSE

[BSD 3-Clause License](./LICENSE)

## CONTRIBUTE
If you have an idea for a new feature or have found a bug, just do a pull request (PR).
