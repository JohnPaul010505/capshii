# Clay Widget Migration Plan — Option A

## Overview
Replace the global `iOSThemeData` (CupertinoAppColors + sfText) with a ClayTokens-based `ThemeData`, then refactor 4 priority pages to use clay widgets (ClayCard, ClayButton, ClayInput, ClayAvatar, ClayChip, ClayProgress) instead of raw Containers/Gestures/Cupertino widgets.

---

## Phase 1: Global Theme (`lib/app/theme.dart`)

### Goal
Single-source ClayTokens theme that all pages inherit via `MaterialApp(theme: clayThemeData)`.

### Changes
| Current | Target |
|---------|--------|
| `iOSThemeData` uses `CupertinoAppColors.*` + `sfText()` | `clayThemeData` uses `ClayTokens.*` colors + `ClayTokens.*` text styles |
| ColorScheme built from Cupertino palette | ColorScheme from ClayTokens: `clayPrimary`, `clayError`, `clayWarning`, `clayAccent`, `clayDarkBase`, `clayDarkSurface`, `clayDarkBorder`, etc. |
| `sfText(...)` for every textTheme entry | `ClayTokens.displayLarge`, `ClayTokens.headlineMedium`, `ClayTokens.bodyLarge`, `ClayTokens.labelLarge`, etc. (with `.copyWith()` where needed) |
| `elevatedButtonTheme` = flat purple | Use ClayTokens colors; clay widgets handle press animation |
| `cardTheme` = flat groupedBackground | Use `ClayTokens.clayDarkSurface` + ClayTokens shadows via custom ClayCard |
| `navigationBarTheme` = Cupertino style | Keep but map colors to ClayTokens |

### File Output
- Replace `iOSThemeData` (lines 288–514) with `clayThemeData`
- Delete `CupertinoAppColors` import, remove `sfText` usage
- Export new theme from `theme.dart`

---

## Phase 2: Priority Page 1 — Login (`lib/features/auth/pages/login_page.dart`)

### Current Structure
- `Scaffold` + gradient background
- `_buildLoginCard()` → `Container` with BoxDecoration (shadows, border, radius)
- `_buildRoleToggle()` → `Container` + `GestureDetector` + AnimatedContainer
- `_buildFloatingField()` → `CupertinoTextField` + Stack for floating label
- Sign-in button → `GestureDetector` + `Container` with gradient

### Clay Widget Mapping
| Current | Target Clay Widget |
|---------|-------------------|
| Login card Container | `ClayCard(variant: ClayCardVariant.elevated, padding: ClayCardPadding.large, animateEntrance: true)` |
| Role toggle | `ClayFilterChips(options: ['MEMBER','TRAINER'], multiSelect: false, style: ClayChipStyle.filled, onChanged: ...)` |
| Floating field | `ClayTextField(label: 'Code', prefixIcon: Icon(CupertinoIcons.mail), ...)` |
| Password field | `ClayPasswordField(label: 'Password', ...)` |
| Sign-in button | `ClayPrimaryButton(label: 'Sign In', onPressed: _login, loading: _loading, fullWidth: true, size: ClayButtonSize.large)` |
| Error banner | `ClayCard(variant: ClayCardVariant.filled, padding: ClayCardPadding.medium, child: Row([Icon(...), Expanded(Text(...)), IconButton(...)]))` |
| Prefix warning | Same pattern with `ClayTokens.clayWarning` |

### Cleanup
- Remove 3 AnimationControllers (clay widgets handle press/tap animation)
- Remove custom `_roleTab` and `_buildFloatingField` methods
- Import `clay_tokens.dart` instead of `design_tokens.dart`

---

## Phase 3: Priority Page 2 — Member Dashboard (`lib/features/member/dashboard/pages/dashboard_page.dart`)

### Current Structure
- `CupertinoPageScaffold` with `clayDarkBase` background
- `_buildNavBar()` → `Container` with bottom border
- `_StatRow` → `GestureDetector` + `Container` with colored icon circle
- Progress section → `Container` with `BoxDecoration`

### Clay Widget Mapping
| Current | Target Clay Widget |
|---------|-------------------|
| Scaffold + SafeArea + Column | `CupertinoPageScaffold` → keep; or `Scaffold` with `ClayTokens.clayDarkBase` |
| NavBar | `ClayCard(variant: ClayCardVariant.filled, padding: ClayCardPadding.small, child: Row([...]))` |
| `_StatRow` | `ClayFeatureCard(icon: ..., title: label, subtitle: null, onTap: onTap, showChevron: true)` |
| Weekly Progress container | `ClayCard(variant: ClayCardVariant.elevated, padding: ClayCardPadding.medium, child: Column([...]))` |

### Cleanup
- Remove `_StatRow` class
- Replace `CupertinoIcons.flag` etc. with `Icons` equivalents
- Use `ClayTokens.spacing.md/lg/xl` for consistent spacing

---

## Phase 4: Priority Page 3 — Member Profile (`lib/features/member/profile/pages/profile_page.dart`)

### Current Structure
- `CupertinoPageScaffold`
- Avatar → `Container` + gradient circle + initials
- Feature list → `_FeatureCard` (Container + GestureDetector)
- Sign-out → `CupertinoButton.filled`

### Clay Widget Mapping
| Current | Target Clay Widget |
|---------|-------------------|
| Avatar Container | `ClayAvatar(size: ClayAvatarSize.xl, initials: ..., onTap: ...)` |
| `_FeatureCard` | `ClayFeatureCard(icon: ..., title: ..., subtitle: ..., onTap: ...)` |
| Sign-out button | `ClayDestructiveButton(label: 'Sign Out', onPressed: ..., icon: CupertinoIcons.square_arrow_right, fullWidth: true)` |
| NavBar | Same pattern as dashboard |

### Cleanup
- Remove `_FeatureCard` class
- Use `ClayAvatar` for avatar with gradient (ClayAvatar supports gradient)

---

## Phase 5: Priority Page 4 — Member Home (`lib/features/member/home/pages/home_page.dart`)

### Current Structure (874 lines, complex)
- `Scaffold` + `ListView`
- `_GreetingRow` → Row with pulse dot + avatar + text
- `_MembershipCard` → Container with border
- `_WeekChart` → Custom bar chart with AnimatedContainer bars
- `_StatRow` + `_StatCard` → `PressableCard` (custom)
- `_TrainerCard` → Container with avatar, star row, button
- `_TodayProgress` → `PressableCard` with LinearProgressIndicator
- `_QuickLogRow` + `_QuickCard` → Animated scale press

### Clay Widget Mapping (major refactor)
| Current | Target |
|---------|--------|
| Scaffold/ListView | Keep `ListView` but use `ClayTokens` spacing |
| Greeting avatar | `ClayAvatar(size: ClayAvatarSize.lg, initials: ..., onTap: ...)` |
| `_MembershipCard` | `ClayCard(variant: ClayCardVariant.elevated, child: Row([...]))` |
| `_WeekChart` | Keep custom chart (no clay equivalent), but wrap in `ClayCard` |
| `_StatCard` | `ClayStatCard(icon: ..., label: ..., value: ..., iconColor: ..., onTap: ...)` |
| `_TrainerCard` | `ClayCard(variant: ClayCardVariant.elevated, child: ClayFeatureCard(...))` |
| `_TodayProgress` | `ClayProgressCard(label: ..., value: ..., progress: ..., icon: ..., progressColor: ..., onTap: ...)` |
| `_QuickCard` | `ClayPrimaryButton` / `ClaySecondaryButton` with `fullWidth: true` in a `Row` |
| Custom press animations | Remove — clay widgets provide press scale + haptics |

### Cleanup
- Remove `_StatCard`, `_QuickCard`, `PressableCard` dependencies
- Replace all hardcoded colors (`Color(0xFF...)`) with `ClayTokens`
- Replace custom animations with `ClayTokens.fast/normal` durations

---

## Phase 6: Secondary Pages (Opportunistic)

After priority 4, remaining 17 pages can be migrated when touched:
- Trainer: dashboard, members_list, member_detail, profile, progress_list, member_progress, chat_list, chat_room
- Member: settings, progress, goals, notifications, measurements, meals, feedback, chat, workout, checkin
- Shared: checkin_page

Each follows same pattern: `Container` → `ClayCard`, `GestureDetector` → `ClayButton`/`ClayFeatureCard`, `TextField` → `ClayInput`, custom cards → `ClayStatCard`/`ClayFeatureCard`/`ClayProgressCard`.

---

## Implementation Order

| Step | Task | Files | Est. Effort |
|------|------|-------|-------------|
| 1 | Create `clayThemeData` in `theme.dart` | `theme.dart` | 1–2 hrs |
| 2 | Update `main.dart` / router to use new theme | `main.dart` | 15 min |
| 3 | Migrate Login page | `login_page.dart` | 2–3 hrs |
| 4 | Migrate Member Dashboard | `dashboard_page.dart` (member) | 1–2 hrs |
| 5 | Migrate Member Profile | `profile_page.dart` (member) | 1–2 hrs |
| 6 | Migrate Member Home | `home_page.dart` | 3–4 hrs |
| 7 | Run `flutter analyze` + manual QA | — | 30 min |
| 8 | (Optional) Migrate Trainer equivalents | trainer/* pages | parallel |

---

## Clay Widget API Reference (from `lib/features/shared/widgets/clay/clay_tokens.dart`)

```dart
// Buttons
ClayPrimaryButton({label, onPressed, loading, icon, fullWidth, size})
ClaySecondaryButton({...})
ClayGhostButton({...})
ClayDestructiveButton({...})
ClayIconButton({icon, onPressed, style, size})

// Cards
ClayCard({child, onTap, variant, padding, animateEntrance, ...})
ClayStatCard({label, value, subtitle, icon, iconColor, onTap, trailing})
ClayFeatureCard({title, subtitle, icon, iconColor, iconBgColor, onTap, trailing, showChevron})
ClayProgressCard({label, value, progress, progressColor, icon, iconColor, onTap})
ClayEmptyState({icon, title, message, actionLabel, onAction})
ClayModalCard({child, padding, maxWidth, borderRadius})

// Inputs
ClayInput({controller, label, hint, errorText, obscureText, prefixIcon, suffixIcon, ...})
ClayTextField({...})
ClayPasswordField({...})
ClaySearchField({...})

// Chips
ClayChip({label, selected, onSelected, style, size, leadingIcon, ...})
ClayFilterChips({options, multiSelect, onChanged, ...})
ClayInputChip({label, selected, onSelected, onDeleted, avatar, ...})

// Avatar
ClayAvatar({imageUrl, initials, size, style, backgroundColor, onTap, showOnlineIndicator})
ClayAvatarGroup({avatars, maxVisible, overlap, size})
ClayAvatarWithStatus({imageUrl, initials, size, statusColor, ...})

// Progress
ClayProgressRing({progress, size, strokeWidth, progressColor, ...})
ClayProgressBar({progress, height, borderRadius, progressColor, label, showPercentage})
ClayStepProgress({currentStep, totalSteps, labels, ...})
ClaySkeleton({width, height, borderRadius})
ClaySkeletonCircle({size})
ClaySkeletonBlock({lines, lineHeight, spacing, lastLineWidthFactor})
```

---

## Success Criteria

1. `flutter analyze` — 0 errors, 0 warnings (except pre-existing unrelated)
2. All 4 priority pages render identically (visual regression check)
3. Press/tap animations feel native (150–200ms spring, haptic on press)
4. Dark mode works (already default)
5. No `CupertinoAppColors` or `sfText` imports remain in migrated files
6. Global `ThemeData` provides consistent colors/text styles for any non-clay-widget usage

---

## Risks & Mitigations

| Risk | Mitigation |
|------|------------|
| Login page custom animations lost | ClayButton/ClayCard provide spring press + fade/slide entrance; add `animateEntrance: true` |
| Home page custom chart/week bars | Keep custom chart, wrap in ClayCard |
| Trainer pages diverge | Use same mapping patterns; share `_buildNavBar` helper |
| Theme migration breaks other pages | Test all 21 pages after Step 1; fix any `Theme.of(context).colorScheme.xxx` mismatches |

---

## Ready to Execute?

If approved, I'll start with **Step 1** (global theme) and proceed sequentially through the 4 priority pages.