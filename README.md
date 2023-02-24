A better dart pub publish, by running tests, fixes, lint, update CHANGELOG file and git commands.

## Using globally as CLI
```dart
dart pub global activate dpp
```
## Using internaly in only one project
```dart
dart pub add dpp
```

```dart
void main() {
  final pubPublisher = DartPubPublish(git: false);

  // Publish a new version with default message
  pubPublisher.run('1.2.0'); // default message: 'Update version number'

  // Publish a new version with a changelog message
  pubPublisher.run('1.3.0', message: 'Added a new feature');

  print('Package published!');
}
```

## LICENSE

[BSD 3-Clause License](./LICENSE)

## CONTRIBUTE
If you have an idea for a new feature or have found a bug, just do a pull request (PR).
