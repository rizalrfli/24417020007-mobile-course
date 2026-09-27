# Local music 1.0.3 compatibility fixes

Based on https://pub.dev/packages/music/versions/1.0.3 (MIT; see LICENSE).

- Android: Gradle namespace, current AndroidX dependencies, immutable notification intents, private broadcast receivers, direct HTTPS streaming without the obsolete HTTP cache dependency, and playback errors sent to Flutter.
- iOS: fix upstream registration/compilation typos, method results, and millisecond seek/position handling. Requires verification on macOS/iOS.
- Web: use the browser audio element through the same music method channel.
- Dart: accept numeric platform timestamps, skip notification artwork downloads on web, and resolve bundled MP3 assets to native temporary files or browser asset URLs.

The app plays full MP3 files supplied in assets/audio. Keep this directory and the path dependency together when sharing the project.
