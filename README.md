# Activity 09 - Local Storage Part II

**Student:** Harshit Jain  
**Pathway:** Graduate / CSC 6370

## 1. Project overview

This extends the existing Activity 08 Flutter project with a card catalogue. One folder contains many cards, and each card belongs to exactly one folder. The original Fall Festival guest roster remains accessible using **Part I roster** on the home screen. No seed records are inserted.

## 2. Flutter version

Verified locally: Flutter 3.47.2 stable, Dart 3.13.2.

## 3. Dependencies

Existing dependencies remain unchanged: Flutter, sqflite, path_provider, path, and cupertino_icons. Tests use flutter_test; analysis uses flutter_lints. No new dependencies or state management frameworks were added.

## 4. Database filename

`MyDatabase.db`, in the application documents directory returned by `getApplicationDocumentsDirectory()`. This is the same filename and location used in Activity 08.

## 5. Previous database version

Version **1**, as found in the existing helper source. The installed device database has not been inspected by the coding assistant.

## 6. New database version

Version **2**, an increase of exactly one.

## 7. Original Part I table

Unchanged schema:

```sql
CREATE TABLE my_table (
  _id INTEGER PRIMARY KEY,
  name TEXT NOT NULL,
  age INTEGER NOT NULL
);
```

The existing `insert`, `queryAllRows`, `queryRowCount`, `update`, and `delete` methods remain available. IDs and saved guest values are not transformed by the migration.

## 8. folders table

```sql
CREATE TABLE folders (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL UNIQUE,
  created_at TEXT NOT NULL
);
```

Folder names are trimmed and must be nonblank. Duplicate names produce a save error and preserve input. `created_at` is a UTC ISO 8601 string.

## 9. cards table

```sql
CREATE TABLE cards (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  title TEXT NOT NULL,
  suit TEXT NOT NULL,
  notes TEXT NOT NULL DEFAULT '',
  image_ref TEXT,
  folder_id INTEGER NOT NULL,
  FOREIGN KEY(folder_id) REFERENCES folders(id) ON DELETE CASCADE
);
CREATE INDEX idx_cards_folder_id ON cards(folder_id);
```

Supported suits: Hearts, Diamonds, Clubs, Spades. Titles are trimmed and must be nonblank. The helper also validates titles and suits before writing.

## 10. Foreign key relationship

`cards.folder_id` references `folders.id`. The nonnullable column and enabled foreign key prevent cards from referencing nonexistent folders. Lists query with the selected folder's real ID. SQL uses bound arguments for IDs; user input is never concatenated into SQL.

## 11. ON DELETE CASCADE behavior

After a named confirmation dialog is confirmed, the helper deletes the parent folder. SQLite removes its child cards through `ON DELETE CASCADE`. The app does not manually delete the children. Canceling the dialog performs no write. Unrelated folders and cards are unaffected.

## 12. image_ref approach

`image_ref` is an optional bundled asset path. Empty input is saved as NULL. Null, empty, broken, and unavailable references show a stable suit symbol (♥ ♦ ♣ ♠). Image failure does not remove the card or hide its title, notes, suit, or IDs. No gallery picker or network access is used. This project includes no card image assets; valid images require adding assets and declaring them in pubspec.yaml.

## 13. Migration strategy

Upgrade the existing installation in place. Keep the same application identity, database filename, documents-directory location, and storage. The version 1 → 2 migration creates only the two new tables and index. It does not drop, rename, clear, or update `my_table`. sqflite runs the creation/upgrade callback in its database-opening transaction; a failed schema migration is reported rather than resetting storage.

**Before first running this new code on the existing installation, capture `evidence/T1_before.jpeg` from the old Activity 08 app.** Record every original guest ID, name, age, and count. Do not uninstall, clear storage, or use a new application ID. If already upgraded, do not reset storage to recreate a before screenshot; document the missing before evidence honestly.

## 14. onCreate behavior

A fresh database receives `my_table`, `folders`, `cards`, and `idx_cards_folder_id`. It starts empty. No sample records or hard-coded IDs are inserted.

## 15. onUpgrade behavior

For `oldVersion < 2`, create the catalogue tables and index. The original Part I table and its rows remain untouched. `onCreate` is not used to migrate an existing database.

## 16. Foreign key configuration

`onConfigure` executes `PRAGMA foreign_keys = ON` before creation or upgrade and on each database open. Cascade deletion therefore uses SQLite's enabled foreign key enforcement.

## 17. Models

Separate files define `Folder` and `Card`, each with typed fields, a constructor, `fromMap`, and `toMap`. `FolderWithCount` pairs a folder with its aggregate card count. The model `Card` is imported with an alias in UI code to avoid collision with Flutter's `Card` widget.

## 18. Repository/database layer

`lib/database_helper.dart` holds all SQL. Added methods: `getFoldersWithCounts`, `getCards`, `insertFolder`, `deleteFolder`, `insertCard`, `updateCard`, and `deleteCard`. Inserts return SQLite-generated integer IDs; updates and deletes return affected-row counts. Zero affected rows receive explicit UI feedback. Primary keys are omitted from new catalogue inserts; card updates identify the original card by its ID. Foreign keys validate the selected folder at write time.

## 19. Screens

- Folder screen: names, real IDs, counts, add, refresh, named delete confirmation, and Part I navigation.
- Card screen: selected folder ID, count, card IDs, titles, suits, notes, image fallback, add, edit, and named delete confirmation.
- Add/Edit form: shared form with required title, folder, and suit; optional notes and asset reference. Cancel writes nothing. Failed saves retain input. Busy saves disable duplicate submission and back navigation.
- Part I roster: original guest add/edit/cancel/delete/refresh and validation remain available.

Async UI changes check `mounted`. Errors are shown in human-readable messages. Use Refresh or Reload folders after read errors.

## 20. Run commands

From `/Users/harshitjain/local_storage_lab`:

```sh
flutter pub get
flutter run
```

For T1, choose the same device and existing app installation. Capture the before screenshot before deploying the upgrade. Do not clear app storage or uninstall.

## 21. Test commands

```sh
flutter analyze
flutter test
```

During implementation, analysis finished with **No issues found**, and **6 automated tests passed**. These cover model round trips, title validation and suit symbols, blank-title rejection, trimmed saves and real ID preservation, failed-write input retention, cancel without writes, and null/empty/broken image fallback. Form tests use an in-memory helper substitute, not a real device database. They do not prove migration, cascade deletion, or restart persistence on the existing installation.

## 22. Release build command

```sh
flutter build apk --release
```

No release APK was built, installed, or device-tested during this change.

## 23. T1–T6 test matrix

Manual results are intentionally unfilled.

| Test | Action | Expected | Observed | Actual IDs / Counts | Pass / Fail |
|---|---|---|---|---|---|
| T1 | Upgrade the same Part I installation to version 2 | New tables and index exist; all previous guest IDs and values unchanged | NOT YET TESTED | NOT YET RECORDED | NOT YET TESTED |
| T2 | Folder A with two cards; Folder B with one | Three distinct card IDs, correct parent IDs and counts 2/1 | NOT YET TESTED | NOT YET RECORDED | NOT YET TESTED |
| T3 | Save one card edit; cancel another | Exactly one row changes; canceled and unrelated rows unchanged | NOT YET TESTED | NOT YET RECORDED | NOT YET TESTED |
| T4 | Record values; force-stop and reopen without clearing storage | Same IDs, values, folders, cards, counts; no duplicates | NOT YET TESTED | NOT YET RECORDED | NOT YET TESTED |
| T5 | Cancel then confirm deletion of a disposable folder | Cancel changes nothing; confirm removes parent and children only | NOT YET TESTED | NOT YET RECORDED | NOT YET TESTED |
| T6 | Null/broken image; blank title save | Suit fallback and card data visible; invalid save writes nothing | NOT YET TESTED | NOT YET RECORDED | NOT YET TESTED |

### Exact manual steps

1. **T1:** Before deploying, open the existing Activity 08 app, refresh the roster, record every ID/name/age and count, and capture `T1_before.jpeg`. Run the new code on that same installation. Open **Part I roster**, refresh, and compare every row and count. Open the catalogue to confirm the new tables are usable. For direct schema verification, use Android Studio Database Inspector on the debug app and inspect:

   ```sql
   PRAGMA user_version;
   PRAGMA foreign_keys;
   SELECT name, sql FROM sqlite_master
     WHERE name IN ('my_table', 'folders', 'cards', 'idx_cards_folder_id');
   SELECT * FROM my_table ORDER BY _id;
   ```

   Expect version 2. Foreign key configuration is connection-specific; a separate inspector connection's setting does not establish the app connection's setting. Record schema and row observations honestly.

2. **T2:** Add Folder A. Note its displayed actual ID. Open it and add two differently titled cards with valid suits. Return home; check count 2. Add Folder B and one card; check count 1. Open both folders and verify all three card IDs are distinct and only the matching parent's cards appear. Capture `T2_cards.jpeg` showing Folder A's two cards with IDs; record Folder B's card and counts in the matrix (an additional screenshot is helpful).
3. **T3:** Record all three cards' values. Edit one, change title/notes, and Save. Confirm the same card ID and exactly one changed row. Edit another, change input, then Cancel. Reopen it and confirm its original values and ID remain. Compare unrelated cards. Database Inspector can show all rows using `SELECT * FROM cards ORDER BY id;`.
4. **T4:** Record folder/card IDs, values, parent IDs, and counts. Force-stop using Android App Info, then reopen the same app without clearing storage. Compare both folders and the original roster. Capture `T4_after.jpeg` showing the same folder/card IDs and count after restart; add extra views if needed to substantiate all recorded values.
5. **T5:** Create a disposable folder and add at least one card. Record its actual IDs and all unrelated counts. Press Delete folder and Cancel; verify nothing changed. Delete again and confirm the named dialog. Verify the folder disappears and unrelated counts stay unchanged. In Database Inspector, query `SELECT * FROM cards WHERE folder_id = <actual_disposable_folder_id>;` with the recorded integer substituted; expect no rows. This verifies persisted children are gone, not merely hidden by the UI.
6. **T6:** Add a card with no image reference and a valid suit. Verify the matching symbol and all card details. Edit it with `missing.png` as the reference, save, and verify the same fallback and preserved data. Attempt an Add and an Edit with a space-only title; Save must show `Enter a title.` and not change rows/counts. Cancel and compare stored data. To exercise a write error, try a duplicate folder name; its input must remain with a clear error.

Only replace NOT YET TESTED / NOT YET RECORDED entries after personally recording results. IDs must come from the app or database, never assumed from creation order.

## 24. Evidence filenames

Required Activity 09 files:

- `evidence/T1_before.jpeg` — user must capture before migration.
- `evidence/T2_cards.jpeg` — user must capture after parent/child creation.
- `evidence/T4_after.jpeg` — user must capture after force-stop/reopen.
- `evidence/analysis_output.txt` — real final Flutter analyzer output.

No screenshots were fabricated. Existing Activity 08 JPEGs, `README_Final.md`, and `evidence/README_Final.md` remain unchanged. The previous Activity 08 analyzer output is preserved in `evidence/analysis_output_activity08.txt`; the required analyzer file now records Activity 09 analysis.

## 25. Known limitations

Manual T1–T6 have not been performed by the coding assistant. Existing device data preservation, real SQLite cascade enforcement, and restart persistence need manual verification. Tests use a helper substitute and do not open the installed database. No bundled card images, gallery picker, folder renaming, or network image support is included. SQLite folder-name uniqueness uses its default case-sensitive comparison. Use the existing supported mobile/native sqflite setup; web support was not added. Release APK/device testing remains outstanding.

## 26. AI assistance disclosure

OpenAI Codex assisted with inspection, the additive migration, models, database methods, screens, validation, image fallback, automated tests, analyzer checks, and documentation. Harshit Jain must personally verify the app and complete the manual results and screenshot evidence. Automated checks are real; manual outcomes and IDs have not been invented.
