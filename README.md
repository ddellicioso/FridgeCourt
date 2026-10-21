# Fridge Court

Solo school app project. Housemates file petty "crimes," a jury votes,
and the fridge passes a joke sentence.

## Status

This is the **Must-have** slice, wired with in-memory mock data (no
Firebase yet) so you can run and demo it immediately:

- Home / case list screen
- File a crime (report) screen
- Case file / jury voting / verdict screen

Colors come from the validated "Snack Pastel" palette
(`lib/theme/app_colors.dart`).

## Run it

```
flutter pub get
flutter run
```

## Next coding steps (Should/Could have, in order)

1. Wire `CaseStore` to Firebase (Auth anonymous sign-in, then swap the
   in-memory list in `lib/data/case_store.dart` for Firestore reads/writes
   — the screens don't need to change, they only depend on `CaseStore`).
2. Add evidence photo upload (Firebase Storage) on the report screen.
3. Add the Snitch System (anyone can report, not just the victim) — already
   supported by the data model, just needs a housemate picker.
4. Add Detective Pings as a simple in-app badge/reminder (not a real push
   notification, per the Won't-have scope).

## Notes

- If `CardThemeData` throws a type error on your Flutter version, change it
  to `CardTheme` in `lib/theme/app_theme.dart` — that's a Flutter-version
  difference, not a design change.
