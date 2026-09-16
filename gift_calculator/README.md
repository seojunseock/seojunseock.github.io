# 축의금 계산기 (Gift Calculator)

A single-screen Flutter app for a wedding reception desk: register each
guest's envelope (name, amount in 만원 units, meal-ticket count) under an
auto-incrementing number, search/edit any entry in place, and export the
final ledger as an Excel or CSV file to share when the cash box is balanced.

No login, no server, no second screen — opening the app goes straight to
the calculator, and everything is stored on-device only.

## Highlights

- **Korean numeral entry**: type "오", "다섯", "십오" etc. (Sino-Korean or
  native Korean number words) into the amount/ticket fields — no need to
  switch the keyboard out of Hangul input. See `lib/utils/korean_numeral.dart`.
- **One-row entry form** with Enter/keyboard-driven flow (name → amount →
  tickets → register), so a receptionist with a Bluetooth keyboard never
  touches the mouse/trackpad.
- **Search** by exact number or partial name match, newest entry first.
- **Inline edit** — tap 수정 on any row, fix it in place, tap 완료; the row
  highlights green for 4 seconds as confirmation.
- **Excel/CSV export** via the OS share sheet (`share_plus`) — the file is
  generated on-device (`excel` package) and handed to whatever app the
  phone already has (KakaoTalk, Mail, Drive, ...), the same way a photo
  goes from the camera roll to a chat app. No server involved.
- **Local-only persistence** via `shared_preferences` — one event's ledger
  lives on the device it was entered on.
- **Light/dark toggle** in the header, independent of the OS setting, since
  research on visual fatigue shows dark mode helps more specifically in
  brightly lit rooms (like a wedding hall) — see the palette rationale in
  `lib/theme/app_palette.dart`.
- Color palette avoids blue (fintech-app cliché) and red (writing a
  person's name in red ink reads as a funeral association in Korean
  custom); it settled on a gold/amber accent instead, with text contrast
  tuned to the ~8:1 ratio research identifies as the comfort/readability
  optimum rather than the harsher ~14:1 of pure black-on-white.

## Running it

This project was scaffolded and verified in a Linux sandbox with no
Android/iOS toolchains, so it has only been proven with `flutter analyze`,
`flutter test`, and `flutter build web`. To actually run it on the target
devices (iPhone, Galaxy, iPad, Galaxy Tab, desktop with a Bluetooth
keyboard), install Flutter on a machine with the relevant SDKs and:

```bash
cd gift_calculator
flutter pub get
flutter run            # picks whatever device/simulator is connected
flutter build ios      # needs Xcode, on macOS
flutter build apk      # needs the Android SDK
flutter build windows  # or macos / linux, for the venue's laptop/PC
flutter build web      # already verified to succeed in this repo
```

## Project layout

```
lib/
  main.dart                    App entry point, theme mode wiring
  models/gift_entry.dart       One ledger row (no, name, amount, tickets)
  services/storage_service.dart   Local persistence (SharedPreferences)
  services/export_service.dart    Excel/CSV generation + native share sheet
  theme/app_palette.dart       Color tokens (ThemeExtension), light + dark
  theme/app_theme.dart         ThemeData built from the palette
  utils/korean_numeral.dart    Sino-/native-Korean numeral parsing
  widgets/ticket_icon.dart     Hand-drawn perforated meal-ticket glyph
  screens/calculator_screen.dart  The one screen
assets/fonts/                  Do Hyeon + Noto Sans KR, bundled so the app
                                renders correctly with no network access
```

## Known trade-offs

- The bundled Noto Sans KR weights are the full CJK font (~6MB each,
  ~24MB total for all weights) since that's what Google Fonts serves —
  fine for a phone/tablet/desktop app, but worth knowing if repo size
  becomes a concern later. A subsetted font would shrink this a lot.
- `share_plus`'s file-sharing is not implemented on Linux desktop (an
  upstream limitation); on Windows/macOS/iOS/Android it works normally.
  On Linux, exporting still writes the file to the temp directory — only
  the "hand it to another app" step is unavailable there.
