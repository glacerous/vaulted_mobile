# VAULTED (Mobile) — Developer Onboarding & Setup Guide

**VAULTED** is an ultra-luxury mobile asset vault built in Flutter with a dark titanium aesthetic (`#131312`, `#1D1D1B`, `#8E8D8A`, `#C0A85C`). It tracks high-value hardware, luxury tech items, Steam/CS2 inventories, warranty lifecycle (LBS service radar), and features an agentic natural language AI assistant (**Valto Sentinel**).

---

## Quick Start for Developers

Follow these steps to get the app running on your machine:

### 1. Prerequisites
- **Flutter SDK**: `>= 3.5.0` (Dart `>= 3.5.0`)
- **Git**
- **Google Chrome** (for fast Web testing) or **Android Studio / Xcode** (for mobile emulator / physical device)

Verify your Flutter environment:
```bash
flutter doctor
```

---

### 2. Clone & Install Dependencies

```bash
# 1. Clone repository
git clone https://github.com/glacerous/vaulted_mobile.git
cd vaulted_mobile

# 2. Install Dart/Flutter packages
flutter pub get
```

---

### 3. Environment Configuration (`.env`)

VAULTED requires a `.env` file in the project root for API integrations (Agentic Valto Chat, Steam API, OCR, etc.).

1. Copy the template:
   ```bash
   # Linux / macOS / Git Bash:
   cp .env.example .env

   # Windows PowerShell:
   Copy-Item .env.example .env
   ```
2. Open `.env` and supply your API keys:
   ```env
   # 1. Steam Web API (For Steam inventory & CS2/Dota items sync)
   # Get free key: https://steamcommunity.com/dev/apikey
   STEAM_API_KEY=your_steam_api_key_here

   # 2. Google Gemini API (For Valto Sentinel Chat & Receipt OCR)
   # Get free key: https://aistudio.google.com/
   GEMINI_API_KEY=your_gemini_api_key_here

   # 3. Polygon Testnet RPC (Public RPC endpoint)
   POLYGON_RPC_URL=https://rpc-amoy.polygon.technology

   # 4. Exchange Rate API (Live FX conversions)
   EXCHANGE_RATE_API_URL=https://open.er-api.com/v6/latest/USD
   ```
> [!IMPORTANT]
> Never commit your real `.env` file with live keys to Git. It is already added to `.gitignore`.

---

### 4. Running the Application

#### Web (Fastest for testing UI & Logic):
```bash
flutter run -d chrome
```

#### Android / iOS Device or Emulator:
```bash
# Check connected devices
flutter devices

# Run on specific target
flutter run -d <device-id>
```

---

## Common Developer Commands

| Command | Description |
| :--- | :--- |
| `flutter pub get` | Fetch/update project dependencies |
| `flutter analyze` | Run static linter checks (keep at 0 issues) |
| `flutter test` | Run project unit & widget tests |
| `flutter clean` | Wipe build caches if assets or bindings get out of sync |
| `flutter run -d chrome` | Launch hot-reloadable web dev server |

---

## Project Architecture

```
lib/
├── core/
│   ├── constants/       # App constants, routes, tokens
│   ├── database/        # SQLite local cache (sqflite)
│   ├── services/        # Gemini AI, Steam API, FX Service, Biometrics, Notifications
│   ├── theme/           # VaultColors, VaultTypography (Titanium luxury system)
│   └── widgets/         # Shared UI components (Valto Mascot, floating docks)
├── models/              # Asset, Warranty, SteamItem data models
├── screens/
│   ├── auth/            # LoginScreen & biometric lock
│   ├── pillars/         # Core tabs (Home Vault, Inventory, Collectibles, Steam Sync)
│   ├── radar/           # WarrantyLBSScreen (geo-distance service centers)
│   ├── search/          # SearchRadarScreen (live item lookup)
│   └── game/            # Vault Sentinel Mini-Game
└── main.dart            # App entrypoint & dotenv initialization
```

---

## Design & UX Principles (Mandatory)

All contributors must respect the rules outlined in `AGENTS.md`:
1. **Dark Titanium Luxury Theme**: Strictly use `VaultColors.background`, `VaultColors.card`, `VaultColors.accent` (`#C0A85C`), and `VaultTypography`.
2. **Thumb Zone Law**: The top 25% of any screen is for glanceable indicators only. All primary interactive actions, floating capsules, and switchers must live within the bottom 40% thumb zone.
3. **No AI Slop / Decorative Mockups**: Every UI element must bind to real data and functional user actions.