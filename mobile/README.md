# 📱 Swasthya Mobile App

> Flutter-based cross-platform mobile application for Android & iOS

## 🚀 Quick Start

```bash
# Install dependencies
flutter pub get

# Run on device/emulator
flutter run

# Build release APK
flutter build apk --release

# Build iOS (requires macOS)
flutter build ios --release
```

## 📁 Project Structure

```
lib/
├── config/           # Theme, routes, constants
├── l10n/             # Localization (English + Nepali)
├── models/           # Data models
├── providers/        # State management (Provider)
├── screens/          # 24 screen modules
│   ├── ai_sathi/     # AI chat, scan, history
│   ├── appointments/ # Booking & video calls
│   ├── doctors/      # Doctor search & profiles
│   ├── emergency/    # SOS & contacts
│   ├── home/         # Dashboard
│   ├── medical_history/  # Health records
│   ├── simulation/   # CPR training
│   └── ...
├── services/         # API, cache, notifications
└── widgets/          # Reusable components
```

## ✨ Key Features

| Feature | Description |
|---------|-------------|
| **AI Saathi** | Bilingual AI chat & voice calls |
| **Medical Report Scanner** | MRI/CT/Lab analysis with OCR |
| **Video Consultations** | Jitsi Meet integration |
| **Offline-First** | Cached data for rural areas |
| **Emergency SOS** | One-tap emergency calls |
| **CPR Simulation** | Interactive first-aid training |
| **Medicine Reminders** | Push notifications with alarms |

## 🔧 Dependencies

| Package | Purpose |
|---------|---------|
| `provider` | State management |
| `go_router` | Navigation |
| `hive_flutter` | Offline storage |
| `url_launcher` | External links & calls |
| `jitsi_meet_flutter_sdk` | Video calls |
| `flutter_local_notifications` | Reminders |
| `image_picker` | Document upload |
| `flutter_tts` or `edgetts` | Voice guidance |

## 🌐 Localization

Supports English and Nepali. Add translations in:
- `lib/l10n/app_en.arb`
- `lib/l10n/app_ne.arb`

## 📝 Environment

Create `.env` file if needed for API configuration:
```
API_BASE_URL=http://your-backend-url:8000
```

## 🔨 Build Commands

```bash
# Debug build
flutter run --debug

# Release APK
flutter build apk --release

# App Bundle for Play Store
flutter build appbundle --release

# Analyze code
flutter analyze

# Run tests
flutter test
```
