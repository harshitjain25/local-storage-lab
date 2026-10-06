# In-Class Activity 08 - Local Storage

**Name:** Harshit Jain  
**Course:** Mobile Application Development  
**Pathway:** Graduate  

## App Summary

This app is a Fall Festival guest roster built with Flutter and SQLite.

The app stores:
- Guest ID
- Guest name
- Guest age

The app supports:
- Add
- Edit
- Cancel Edit
- Delete
- Refresh
- Input validation
- Persistent local storage

## Storage Design

The app uses SQLite through the `sqflite` package.

**Database:** `MyDatabase.db`

**Table:** `my_table`

**Columns:**
- `_id INTEGER PRIMARY KEY`
- `name TEXT NOT NULL`
- `age INTEGER NOT NULL`

The database helper is initialized once before the main app is displayed.

## Validation

The guest name must not be empty after trimming spaces.

The age must:
- be a whole number
- be between 0 and 130 inclusive

The app rejects:
- blank names
- text instead of age
- decimal ages
- negative ages
- ages greater than 130

Invalid input does not create or update a database row.

## Flutter Analyze

`flutter analyze` was run successfully.

```text
Analyzing local_storage_lab...
No issues found! (ran in 1.0s)
```

## Manual Test Results

| Test | Action / Input | Expected | Observed | Pass / Fail |
|---|---|---|---|---|
| T1 | Empty roster | Count 0 and empty-state message | Pending testing | Pending |
| T2 | Add River, 21 and River, 34 | Count 2 with distinct generated IDs | Pending testing | Pending |
| T3 | Edit River B to 99 and Cancel, then edit again and Save age 35 | Cancel keeps 34, Save changes only B to 35 | Pending testing | Pending |
| T4 | Stop and relaunch the same installed app | Same IDs, names, ages, and count remain | Pending testing | Pending |
| T5 | Cancel deletion of A, then confirm deletion | Cancel keeps count 2, confirmed delete leaves only B and count 1 | Pending testing | Pending |
| T6 | Invalid names/ages, then valid ages 0 and 130 | Invalid inputs rejected; 0 and 130 accepted | Pending testing | Pending |

## Prompt 1 - The Disappearing-Data Mystery

Before T4, I predict that the saved guest records will still be present after a full app restart because they are stored in SQLite instead of only being stored in widget memory.

The app initializes `DatabaseHelper` in `main()`. The roster screen then calls `queryAllRows()` and `queryRowCount()` from `initState()`, and the returned data is shown in the visible guest list.

My actual IDs, values, count, restart method, and before/after screenshot references will be added after completing T4.

An observation that would disprove my claim is if the app restarts successfully but the previously saved rows are missing even though I did not clear storage or uninstall the app.

## Prompt 2 - Two Rivers, One Wrong Edit

The app uses the database-generated `_id` to identify each guest. This matters because two guests can have the same name, such as River.

When editing, the selected integer ID is stored and included in the update map, so only the intended database row is changed.

The actual IDs for River A and River B and the observed results will be added after completing T3.

## Prompt 3 - My Usability Walkthrough

The app reuses the same form for both adding and editing guests. When Edit is selected, the current guest values are loaded into the fields and the Add button changes to Save.

The app also provides clear validation messages, a Cancel Edit button, a Refresh button, record count, and confirmation before deletion.

One small usability improvement I would consider is making the success feedback more visually noticeable after Add, Edit, Delete, and Refresh so the user can identify the result faster.

## Prompt 4 - Defend the Storage Boundary

I chose to keep validation in the Flutter UI before calling the database helper. The database schema uses `NOT NULL`, but that alone would still allow values such as an empty string for the name or a negative age.

The UI therefore checks that the trimmed name is not blank and that age is a whole number from 0 through 130 before a database write is attempted.

If the schema changes later, such as adding a new required column, existing databases may not automatically receive that change because `onCreate` only runs when the database is first created.

A versioned migration would be needed to safely update existing installations.

## Required Evidence

These items will be added after the manual test run:

- Actual River A ID
- Actual River B ID
- Actual observed counts for T1 to T6
- `T4_before.png`
- `T4_after.png`
- `T6_invalid.png`
- Exact T4 stop/relaunch method

## Project Files

Important project files include:

```text
lib/
├── main.dart
└── database_helper.dart

evidence/
└── analysis_output.txt

README.md
pubspec.yaml
pubspec.lock
```
