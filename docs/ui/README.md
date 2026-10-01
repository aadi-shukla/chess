# UI & Design System (Phase 11)

Material 3 polish, responsive layouts, motion, and accessibility across mobile, tablet, desktop, and web.

## Theme (`lib/app/theme/`)

| File | Purpose |
|------|---------|
| `app_theme.dart` | M3 `ColorScheme.fromSeed`, component themes |
| `app_colors.dart` | Brand + surface tokens |
| `app_typography.dart` | Inter + Playfair Display |
| `app_breakpoints.dart` | Responsive helpers |
| `app_motion.dart` | Durations, curves, reduced motion |

### Light / Dark

- **Light** — warm parchment background (`#F8F5F0`), white cards
- **Dark** — GitHub-style dark (`#0D1117` / `#161B22`)
- Toggle in **Settings → Theme** (light / system / dark), persisted in Hive

## Responsive breakpoints

| Name | Width | Navigation |
|------|-------|------------|
| Mobile | ≤ 450px | Bottom `NavigationBar` |
| Tablet | 451–800px | `NavigationRail` (collapsed) |
| Desktop | 801–1200px | Extended `NavigationRail` |
| 4K / Web wide | > 1200px | Max content width 1120px |

Helpers: `AppBreakpoints.isDesktop(context)`, `pagePadding(context)`, `contentMaxWidth(context)`.

## Shared widgets (`lib/app/widgets/`)

- `AdaptiveShell` — bottom bar vs side rail
- `ResponsiveContent` — centered max-width + padding
- `AnimatedTabContent` — fade + slide tab transitions
- `FadeIn` — splash / hero entrance

## Animations

- Tab switches: 280ms ease-out (disabled when `MediaQuery.disableAnimations`)
- Route transitions: fade-in default via GetX
- Board move animation: existing 220ms piece slide (offline/online)

## Accessibility

- Minimum 48dp tap targets on buttons and nav items
- `Semantics` on app title, splash, auth headers
- Text scale clamped to 0.9–1.35× for layout stability
- Tooltips on icon-only actions
- Focus/hover/highlight colors from theme

## Performance

- `AnimatedSwitcher` keyed by tab index (avoids full tree rebuild)
- `RepaintBoundary` not added globally — add per heavy widget if profiling shows need
- Google Fonts loaded once via theme
- Clamping scroll wrapper on web for overscroll

## Key screens updated

- **Home** — adaptive shell, animated tabs, dashboard quick actions grid
- **Settings** — two-column layout on desktop
- **Splash** — fade-in entrance
- **Auth** — responsive card width via `AppBreakpoints`

## Testing

```bash
flutter test test/widget/app_breakpoints_test.dart
```
