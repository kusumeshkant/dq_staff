# Design System Audit — DQ Staff
**Branch**: feature/design-system-dq-staff | **Date**: 2026-05-15

---

## Architecture
- **State**: GetX (GetxController, Obx)
- **Architecture**: Clean (domain / data / presentation)
- **Material**: Material 3 (`useMaterial3: true`)
- **Theme modes**: Light (blue) only — dark mode NOT implemented

---

## Existing Design System Files

| File | Status |
|------|--------|
| `lib/src/theme/app_theme.dart` | Partial — ThemeData only |
| `lib/widgets/app_glass_card.dart` | Good — reusable |
| `lib/widgets/themed_background.dart` | Good |

**Missing**: No color tokens, no typography tokens, no spacing system, no semantic colors, no status badges, no ds_loading, no ds_empty_state

---

## Hardcoded Colors (Critical)

### Invite code page — completely divergent color scheme
```dart
// invite_code_page.dart — uses NONE of the app theme:
Color(0xFF0A0A1A)    — dark background (not in AppTheme)
Color(0xFF4CAF50)    — green accent (not in AppTheme)
```

### Status colors (scattered across order/product screens)
```dart
Colors.orange        — pending/preparing
Colors.green         — completed/active
Colors.red           — cancelled/error
Colors.blue          — info/ready
Colors.grey          — neutral
Colors.orange.shade300, .shade700
Colors.green.shade700
Colors.red.shade600
```

### Brand colors (repeated inline)
```dart
Color(0xFF1565C0)    — primary blue (app theme seed)
Color(0xFF0D1B2A)    — dark navy background
Colors.white.withValues(alpha: various)
Colors.black.withValues(alpha: various)
```

---

## Hardcoded Typography (Critical)

No TextTheme extension. All TextStyle inline.

### Font sizes found
```
10, 11, 12, 13, 14, 15, 16, 17, 18, 20, 24, 28
```

### Files with hardcoding
- `presentation/invite/invite_code_page.dart` — completely custom style (no AppTheme)
- `presentation/orders/orders_page.dart` — status text sizes
- `presentation/products/products_page.dart` — product card text
- `presentation/home/home_page.dart` — section headers

---

## Hardcoded Spacing (Critical)

### SizedBox heights — all magic numbers
```
6, 8, 10, 12, 14, 16, 18, 20, 24, 28, 32, 36
```

### Border radius values
```
8, 12, 16, 20, 24, 28
```

### EdgeInsets patterns
```
EdgeInsets.all(8, 12, 16, 20, 24)
EdgeInsets.symmetric(horizontal: 16/20, vertical: 8/12/16)
EdgeInsets.only(bottom: 8/12/16)
```

---

## Critical Issues

### 1. invite_code_page.dart — completely off-theme
The invite code page uses its own hardcoded dark theme (`0xFF0A0A1A` background, `0xFF4CAF50` green) with zero reference to AppTheme. This creates a jarring visual break when users arrive at invite entry.

**Fix**: Migrate to AppGlassCard + AppTheme colors.

### 2. No spacing system
Every SizedBox and EdgeInsets is a magic number. Values like `SizedBox(height: 6)`, `SizedBox(height: 18)`, `SizedBox(height: 28)` appear inconsistently and create irregular visual rhythm.

### 3. No semantic status colors
Order status colors (pending/preparing/ready/completed/cancelled) are hardcoded inline in orders_page and products_page as `Colors.orange`, `Colors.green`, etc. These should be semantic tokens.

---

## Screen Inventory

| Screen | File | Hardcoding severity |
|--------|------|---------------------|
| LoginPage | `presentation/auth/login_page.dart` | MEDIUM |
| HomePage | `presentation/home/home_page.dart` | MEDIUM |
| OrdersPage | `presentation/orders/orders_page.dart` | HIGH |
| ProductsPage | `presentation/products/products_page.dart` | HIGH |
| InviteCodePage | `presentation/invite/invite_code_page.dart` | CRITICAL |
| ProfilePage | `presentation/profile/profile_page.dart` | LOW |

---

## Phase 2 Target Structure

```
lib/
└── design_system/
    ├── tokens/
    │   ├── app_colors.dart        # Color tokens (brand blue, semantic)
    │   ├── app_typography.dart    # TextStyle tokens
    │   ├── app_spacing.dart       # Spacing + radius tokens
    │   └── app_shadows.dart       # Shadow + blur tokens
    ├── theme/
    │   └── app_theme.dart         # ThemeData (extended with TextTheme)
    └── widgets/
        ├── ds_glass_card.dart     # Standard glass card
        ├── ds_button.dart         # Primary + secondary buttons
        ├── ds_input_field.dart    # Text input
        ├── ds_status_badge.dart   # Order status badges (centralized)
        ├── ds_loading.dart        # Loading states
        └── ds_empty_state.dart    # Empty states
```

---

## Migration Priority

1. **CRITICAL first**: Migrate `invite_code_page.dart` to use AppTheme/AppGlassCard
2. **Phase 2**: Create `lib/design_system/tokens/` — colors, typography, spacing
3. **Phase 3**: Add `ds_status_badge` (replaces inline status colors in orders/products)
4. **Phase 5**: Migrate all screens — orders_page, products_page, home_page
5. **Phase 6**: Validate no hardcoded values remain, verify dark mode feasibility
