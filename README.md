# Fridge Court

Solo school app project. Housemates file petty "crimes," a jury votes,
and the fridge passes a joke sentence.

## Status

All Must-Have user stories are implemented (except #7, shareable
verdict card — explicitly out of scope for now):

1. **Household & nickname** — create/join a household by code, pick a
   unique nickname, edit it later (`housecode_screen.dart`,
   `home_screen.dart`, `household_service.dart`).
2. **File a crime, 3 taps or fewer** — pick who did it, pick a crime off
   a severity-grouped menu (minor/medium/major), the second tap files
   the case immediately (`report_screen.dart`, `data/crime_menu.dart`).
3. **Case list & case file** — home screen lists cases with status,
   severity, and a live vote tally; tapping opens the full case file
   (`home_screen.dart`, `widgets/case_card.dart`).
4. **Plea step** — the accused can plead guilty (skips the trial, gets
   a lighter "plea deal" sentence) or not guilty (opens jury voting)
   (`verdict_screen.dart` → `_PleaSection`, `data/sentence_pool.dart`).
5. **Jury voting, accuser/accused blocked** — every other household
   member can vote guilty/not guilty; the person who filed the case and
   the person accused are blocked from voting on their own case
   (`verdict_screen.dart` → `_TrialSection`, `case_store.dart.castVote`).
6. **Automatic verdict** — once every eligible juror has voted, the
   verdict resolves itself (majority wins, tie = not guilty), pulling a
   severity-matched sentence that avoids repeating the same person's
   last sentence twice in a row; a 24-hour timeout resolves any case
   still open on whatever votes it has (`case_store.dart`
   `_maybeAutoResolve` / `checkTimeouts` / `_pickSentence`).

Not implemented (per MoSCoW, intentionally skipped for now):

- **#7 Shareable verdict card / image export** — Won't-have-for-now.
- Evidence **photo** upload (there's a text evidence note field instead).
- Real push notifications (the in-app notification bell covers this
  while the app is open).

Colors come from the validated "Snack Pastel" palette
(`lib/theme/app_colors.dart`).

## Demo mode (for recording the video, or trying it with no setup)

`lib/demo_mode.dart` has one switch:

```dart
const bool kDemoMode = true;
```

With `kDemoMode = true`, the app skips Firebase entirely and runs on an
in-memory `CaseStore.demo()` pre-loaded with four sample cases, so
every screen — filing a case, pleading, voting, the automatic verdict —
is fully interactive with zero setup. This is what the recorded demo
video should use.

## Run it in demo mode (no Firebase needed)

```
flutter pub get
flutter run
```

## Switching to real Firebase later

1. Install the Firebase CLI and `flutterfire_cli`, then from this
   project's folder run `flutterfire configure` — this generates a real
   `lib/firebase_options.dart`, replacing the placeholder stub that's
   in the repo now (it only exists so the project compiles without a
   configured Firebase project).
2. Turn on Anonymous auth and Firestore in that Firebase project.
3. Flip `kDemoMode` to `false` in `lib/demo_mode.dart`.

Nothing else needs to change — every screen talks to `CaseStore`, which
already has a real Firestore-backed constructor (`CaseStore(...)`)
alongside the demo one; they share the exact same public API.

`firestore.rules` has the security rules to deploy alongside this
(member-only read/write, one vote per person).

## Next coding steps (Should/Could have, in order)

1. Add evidence **photo** upload (Firebase Storage) on the report
   screen, alongside the existing text evidence note.
2. Add Detective Pings as a richer in-app badge/reminder (the
   notification bell already does a basic version of this).
3. Shareable verdict card / image export (Must-Have #7, deferred).

## Notes

- If `CardThemeData` throws a type error on your Flutter version, change it
  to `CardTheme` in `lib/theme/app_theme.dart` — that's a Flutter-version
  difference, not a design change.
- This repo has no `android`/`ios`/`web` platform folders — run
  `flutter create .` in this directory once (keeps `lib/` and
  `pubspec.yaml` as-is) if you need to generate them.
