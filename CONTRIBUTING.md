# Contributing

Contributions are welcome! Please open an issue first to discuss what you'd like
to change, then submit a pull request.

## How to contribute

1. Fork the repo and create a branch from `main`.
2. Make your changes and run the quality checks:
   - `flutter pub get`
   - `flutter analyze`
   - `flutter test`
3. Commit with a clear message and open a pull request against `main`.

## Code style

This project uses the recommended Flutter lints
(`package:flutter_lints/flutter.yaml`). Run `flutter analyze` before pushing
and resolve any new errors or warnings.

## Firebase configuration

Never commit real Firebase keys. Copy
`lib/config/firebase_config.example.dart` to
`lib/config/firebase_config.dart` and fill in your own project values locally.

## Security

Firestore rules in `firestore.rules` are intentionally open in this repository
for development. Tighten them before deploying to production and validate with
the Firebase Emulator Suite.
