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
- blank or space-only names
- text instead of an age
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

The analyzer output is also saved in:

```text
evidence/analysis_output.txt
```

## Manual Test Results

| Test | Action / Input | Expected | Observed | Pass / Fail |
|---|---|---|---|---|
| T1 | Refresh empty roster | Count 0 and empty-state message | Roster opened empty and Refresh kept the count at 0 | Pass |
| T2 | Add River, 21 and River, 34 | Count 2 with two different generated IDs | River A received ID 1 and River B received ID 2. Count became 2 | Pass |
| T3 | Edit B to 99 and Cancel, then edit B again and Save age 35 | Cancel keeps B at 34. Save changes only B to 35 while A stays 21 | Cancel did not change B. Saving changed ID 2 to age 35, ID 1 stayed age 21, and count stayed 2 | Pass |
| T4 | Stop and relaunch the same installed app without clearing data | Same IDs, names, ages, and count remain | Before and after restart, ID 1 was River age 21, ID 2 was River age 35, and count stayed 2 | Pass |
| T5 | Cancel deletion of A, then confirm deletion and Refresh | Cancel keeps count 2. Confirmed deletion leaves only B and count 1 | Cancel did not delete A. After confirming deletion of ID 1, only ID 2 remained and count became 1 | Pass |
| T6 | Test invalid values, then add Acorn age 0 and Oak age 130 | Invalid values rejected. Ages 0 and 130 accepted. Final count 3 | Space-only name, `abc`, `1.5`, `-1`, and `131` were rejected. Acorn age 0 received ID 3 and Oak age 130 received ID 4. Final count was 3 | Pass |

## Actual Generated IDs

- River A = ID 1
- River B = ID 2
- Acorn = ID 3
- Oak = ID 4

## Required Screenshots

The required screenshots are:

- `T4_before.png`
- `T4_after.png`
- `T6_invalid.png`

### T4 Before Restart

`T4_before.png` shows:
- River, age 21, ID 1
- River, age 35, ID 2
- Record count 2

### T4 After Restart

`T4_after.png` shows:
- River, age 21, ID 1
- River, age 35, ID 2
- Record count 2
- The same data was loaded again after restarting the app

### T6 Invalid Input

`T6_invalid.png` shows:
- Blank guest name rejected
- Age 21 entered
- Validation message: `Please enter a guest name.`
- Record count stayed 1
- River ID 2 remained unchanged

## Prompt 1 - The Disappearing-Data Mystery

Before T4, I predicted that the saved guest records would still be present after a full app restart because they were stored in SQLite instead of only in widget memory. Before the restart, the app showed River ID 1 age 21 and River ID 2 age 35 with a count of 2 in `T4_before.png`.

For the restart, I stopped the Flutter debug session, used Android App Info to **Force stop** the app, and then reopened the same installed app without clearing storage or uninstalling it. After reopening, `T4_after.png` showed the same IDs, names, ages, and count.

In my implementation, `DatabaseHelper` is initialized in `main()`. When the roster screen starts, `initState()` calls the load method, which uses `queryAllRows()` and `queryRowCount()`, and the returned values are displayed in the list.

My claim would be disproved if the same installation reopened successfully but the previously saved rows were missing even though the app had not been uninstalled and its storage had not been cleared.

## Prompt 2 - Two Rivers, One Wrong Edit

The two River records had different database-generated IDs: A was ID 1 and B was ID 2. I used the integer `_id` to identify which row should be edited instead of using the guest name, because both rows had the same name.

I first changed River B from age 34 to 99 and pressed Cancel Edit, which left B unchanged. I then edited ID 2 again and saved age 35. River A stayed age 21, River B became age 35, and the record count stayed 2.

## Prompt 3 - My Usability Walkthrough

The app reuses the same form for both adding and editing guests. When Edit is selected, the current guest values are loaded into the fields, the Add button changes to Save, and Cancel Edit lets the user leave edit mode without writing a change.

The app also gives validation feedback, shows the record count, confirms deletion, and displays text feedback after database actions. One small improvement I would consider is making success messages more visually noticeable so the user can identify the result of Add, Edit, Delete, and Refresh more quickly.

## Prompt 4 - Defend the Storage Boundary

I chose to validate data in the Flutter UI before calling the database helper. The SQLite schema uses `NOT NULL`, but that alone would still allow values such as an empty string for the name or a negative age, so the UI checks that the trimmed name is not blank and that age is a whole number from 0 through 130.

The T6 results support this boundary because invalid values were rejected without changing the stored records, while the valid boundary ages 0 and 130 were accepted.

If the schema changes later, such as adding a new required column, existing databases may not automatically receive that change because `onCreate` only runs when the database is first created. A versioned migration would be needed to update existing installations safely.

## Project Files

Important project files include:

```text
lib/
├── main.dart
└── database_helper.dart

evidence/
├── analysis_output.txt
├── T4_before.png
├── T4_after.png
└── T6_invalid.png

README.md
pubspec.yaml
pubspec.lock
```

## Submission Notes

This activity is submitted as one source archive containing the Flutter project, README, analyzer output, and required screenshots.

No release APK is required.
