# VAULTED

Mobile asset and inventory tracker built with Flutter. Tracks hardware assets, Steam and CS2 inventories, warranty expiry via local service centers, and includes an assistant for quick logging and asset queries.

## Getting Started

### 1. Requirements
- Flutter SDK (Dart 3.5+)
- Git
- Google Chrome or an Android/iOS device/emulator

Run `flutter doctor` to confirm your setup.

### 2. Setup
Clone the repository and install dependencies:

```bash
git clone https://github.com/glacerous/vaulted_mobile.git
cd vaulted_mobile
flutter pub get
```

### 3. Environment Variables (.env)
Create your `.env` file from the example:

```bash
cp .env.example .env
```

On Windows PowerShell:
```powershell
Copy-Item .env.example .env
```

Open `.env` and fill in your keys:
- `STEAM_API_KEY`: Steam Web API key for syncing inventories (https://steamcommunity.com/dev/apikey)
- `GEMINI_API_KEY`: Google Gemini API key for assistant and OCR (https://aistudio.google.com/)
- `POLYGON_RPC_URL`: Optional RPC URL (defaults to Amoy testnet)
- `EXCHANGE_RATE_API_URL`: Currency rates endpoint

Do not commit `.env`. It is ignored by git.

### 4. Running the App

Web:
```bash
flutter run -d chrome
```

Mobile device or emulator:
```bash
flutter run
```

## Useful Commands

- `flutter pub get`: Fetch dependencies
- `flutter analyze`: Check for lint and syntax errors
- `flutter test`: Run unit and widget tests
- `flutter clean`: Reset build cache

## Project Structure

- `lib/core/`: Constants, database helpers, theme, and API services (Gemini, Steam, FX).
- `lib/models/`: Data classes for assets, warranties, and items.
- `lib/screens/`: App screens (auth, home vault, inventory, warranty radar, search, game).
- `lib/main.dart`: Entry point.