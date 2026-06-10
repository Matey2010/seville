# Seville Interface

This directory contains the Flutter and Flame application for Seville.

Run Flutter commands from this directory:

```sh
flutter pub get
flutter analyze
flutter run
```

The interface will consume generated Dart protobuf messages from the
repository's `proto/` workspace once the contract layer is implemented.

Architecture and repository-wide decisions are documented in
[`../docs/seville-architecture-plan.md`](../docs/seville-architecture-plan.md).
