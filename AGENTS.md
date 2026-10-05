# VAULTED — Mobile Architecture & Ergonomics Guidelines

This repository is **VAULTED**, an ultra-luxury mobile asset vault built in Flutter with a Vantis Vault dark titanium aesthetic (`#131312`, `#1D1D1B`, `#8E8D8A`, `#C0A85C`).

Every AI assistant working in this codebase **MUST STRICTLY COMPLY** with the following rules:

---

## 1. Mobile Thumb Zone & Ergonomics Law (Mandatory)
- **Top 25% is for Glance Only**: App title, total balance counters, status badges. **NEVER** place primary frequent-switch controls (such as timezone pills, category tabs, or action bars) in the top header area.
- **Bottom 40% is for Thumb Touch**: Primary interactive controls, floating capsules, bottom sheets, segment switchers, and confirm buttons must be reachable by a user holding the phone with one hand.
- **No Redundant Indicators**: Do not place an indicator in the top header and then place a duplicate selector right next to it.
- **No Forced Decorative Containers ("AI Slop")**: Never add isolated boxes with decorative gimmicks that do not connect to real user data or functional utilities.

---

## 2. Design System & Tokens
- **Canvas / Background**: `VaultColors.background` (`0xFF131312`)
- **Card Surface**: `VaultColors.card` (`0xFF1D1D1B`)
- **Hairline Borders**: `VaultColors.hairline` (`0xFF2A2A28`)
- **Signature Accent**: `VaultColors.accent` (`0xFFC0A85C`, warm luxury gold)
- **Primary Ink**: `VaultColors.ink` (`0xFFF2F2EF`)
- **Secondary Ink**: `VaultColors.ink2` (`0xFF8F8F8A`)
- **Typography**: Clean monospace for numbers/codes/telemetry (`VaultTypography.mono`), refined sans-serif for titles/labels (`VaultTypography.sans`).

---

## 3. Interactive Floating Controls
- For global filter/timezone switchers on feed screens, use an anchored **Floating Thumb Dock** floating gracefully above the bottom navigation bar, with smooth haptic feedback and blurred/tinted container background.
