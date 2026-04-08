# meu_app

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## API local (flowly_mobal_api)

Por padrao o app usa backend local no desenvolvimento:

- Web/Chrome: `http://localhost:5000`
- Android Emulator: `http://10.0.2.2:5000`

Para sobrescrever a URL da API, use `--dart-define`:

```bash
flutter run -d chrome --dart-define=FLOWLY_API_URL=http://localhost:5000
```
