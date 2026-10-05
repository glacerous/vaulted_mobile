---
name: mobile-ergonomics-ux
description: >-
  Enforces mobile-first ergonomics, thumb-zone reachability, and clean luxury mobile UX guidelines for Flutter mobile apps.
  Use when designing screens, navigation patterns, interactive controls, or evaluating layout usability.
---

# Mobile Ergonomics & Clean Luxury UX Skill

This skill enforces strict mobile-first design principles, eliminating desktop-web anti-patterns and ensuring all interactive controls are naturally reachable by one hand.

---

## 1. The Thumb Zone Law (Steven Hoober & Fitts's Law)

Modern mobile screens (6.1" to 6.8") require single-handed usability:

1. **Top Zone (0% - 25% screen height) — "Glance Only"**:
   - Strictly reserved for passive information: brand title, current status badges, large numerical counters, non-interactive indicators.
   - **NEVER** place primary frequent actions, multi-option switchers, or tabs here that require the user to stretch their thumb across the entire screen.

2. **Middle Zone (25% - 60% screen height) — "Content & Perception"**:
   - Feed cards, detailed descriptions, charts, and scrollable content.

3. **Bottom Zone (60% - 100% screen height) — "The Natural Thumb Zone"**:
   - Primary interactive triggers, floating filter capsules, bottom sheets, segment switchers, action buttons, and navigation.
   - Elements must be comfortably tappable with the thumb without shifting the grip.

---

## 2. Anti-Desktop Web Anti-Patterns (BANNED)

- ❌ **Top-Heavy Tab/Pill Bars**: Placing a horizontal 4-pill selector right under the app header.
- ❌ **Redundant Controls**: Putting a status badge (e.g. `WITA`) on the top-right and immediately duplicating it with a full selector bar right below it.
- ❌ **AI-Generated Slop Containers**: Adding random standalone decorative boxes/gadgets that have no functional tie to the actual business logic or user data.
- ❌ **Sub-44pt Tap Targets**: Any interactive button smaller than 44x44 dp causes missed taps and user frustration.

---

## 3. Preferred Mobile Design Patterns

- **Floating Thumb-Dock**: Floating glassmorphic capsules anchored at the bottom (above bottom nav) for rapid switching (e.g., timezone, category filters).
- **Modal Bottom Sheets**: For complex inputs or multi-step selections instead of full-screen top dropdowns.
- **Contextual In-Card Controls**: If an action only affects an event card (like viewing a drop in London vs WIB), embed the conversion or toggle right inside that card.
- **Haptic & Visual Feedback**: Subtle micro-scaling (`Transform.scale`), smooth transitions (150–250ms `Curves.easeOutCubic`), and distinct active/inactive states matching the dark luxury palette.
