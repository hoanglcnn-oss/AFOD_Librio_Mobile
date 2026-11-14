# week34_project

Librio Mobile Application (AFOD).

## Getting Started

This project is a Flutter application for library borrowing, book discovery, reservations, and member management.

A few resources to get you started:
- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

---

## Environment & API Configuration

The API base URL is configured at compile time via Flutter's `--dart-define` mechanism in `ApiConstants.baseUrl`.

### Default API URL

If `--dart-define=API_BASE_URL=...` is not passed, the app defaults to the production endpoint:
```text
https://api.leorank.site/api
```

### Overriding the Base URL

Pass the `API_BASE_URL` environment variable during `flutter run` or `flutter build`:

#### 1. Standard run (default production URL)
```bash
flutter run
```

#### 2. Android Emulator (local backend)
Android emulator maps the host machine's `localhost` to `10.0.2.2`:
```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api
```

#### 3. iOS Simulator / Web / Desktop (local backend)
iOS simulator and desktop share the host network stack:
```bash
flutter run --dart-define=API_BASE_URL=http://localhost:8000/api
```

#### 4. Physical Mobile Device (local backend via LAN)
When debugging on a physical device over Wi-Fi, use your workstation's LAN IP address:
```bash
flutter run --dart-define=API_BASE_URL=http://192.168.1.100:8000/api
```

#### 5. Release / Staging Build
```bash
flutter build apk --dart-define=API_BASE_URL=https://staging.example.com/api
flutter build appbundle --dart-define=API_BASE_URL=https://api.leorank.site/api
```

> [!NOTE]
> `String.fromEnvironment` values are resolved at **compile time**. Changing `--dart-define` parameters requires a full application restart / rebuild, not a hot reload or hot restart.
