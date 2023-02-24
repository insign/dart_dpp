# dpp

A better dart pub publish, by running tests, fixes, lint, update CHANGELOG file and git commands.

## Installing globally as CLI

```dart
dart pub global activate dpp
```

> If you receive a "Warning" just follow the instructions and reopen the console. If you need more help visit [Running a script from your PATH](https://dart.dev/tools/pub/cmd/pub-global#running-a-script-from-your-path).

## Simple CLI usage

```bash
dpp <1.2.3|patch|minor|major> [optional commit/changelog message]
```

Examples:

```bash
dpp 1.0.1 Typo fix
```

```bash
dpp minor New great feature # version will be 1.1.0
```

```bash
dpp major Rewritten code from Rust to Dart # 2.0.0
```

Simple run `dpp` to see all flags available.

>ProTip: create an alias "pp" with your default flags. If my standard do not fits for you. E.g. put the following in you bashrc/zshrc: `alias pp="dpp --no-git --no-tests"`

## Using internaly in only one project

```bash
dart pub add dev:dpp # dev: means you will use only in development
```

```dart
void main() {
  final pubPublisher = DartPubPublish(git: false);

  // Publish a new version with default message
  pubPublisher.run('1.2.1'); // default message: 'Update version number'

  // Publish a new version with a changelog message
  pubPublisher.run('minor', message: 'Added a new feature');

  print('Package published!');
}
```

## LICENSE

[BSD 3-Clause License](./LICENSE)

## CONTRIBUTE

If you have an idea for a new feature or have found a bug, just do a pull request (PR).
