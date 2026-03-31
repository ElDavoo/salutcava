# Salut, ça va ?

Flutter simulator for the 2-step French greeting protocol in multi-person
conversations.

## Features

- Configurable people count from 2 to 20.
- Configurable concurrent conversations from 1 to 5.
- Deterministic and random pair scheduling.
- Tap-to-advance simulation (one message per tap).
- Circular visualization with directional arrows and speech bubbles.
- Completion summary with total conversation turns and elapsed real time.

## Nix Development Environment

This repository includes a `flake.nix` dev shell with Flutter, Android SDK, and
Java.

The Nix SDK now includes Flutter's required NDK (`28.2.13676358`), so builds can
run directly from the immutable Nix SDK without copying SDK/NDK directories into
the project.

If you used the previous local SDK workaround, remove the override once:

```bash
rm -rf .android-sdk
rm -f android/local.properties
```

```bash
nix develop
flutter doctor
flutter run
```

## Quality Checks

```bash
flutter analyze
flutter test
```
