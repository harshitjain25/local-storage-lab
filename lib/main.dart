import 'package:flutter/material.dart';

import 'database_helper.dart';
import 'screens/folders_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final helper = DatabaseHelper();

  try {
    await helper.init();
  } catch (error, stackTrace) {
    debugPrint('Database initialization failed: $error\n$stackTrace');

    runApp(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text(
              'Could not open local storage. Restart the app and check the logs.',
            ),
          ),
        ),
      ),
    );

    return;
  }

  runApp(DirectoryApp(helper: helper));
}

class DirectoryApp extends StatelessWidget {
  final DatabaseHelper helper;

  const DirectoryApp({super.key, required this.helper});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Card catalogue',
      home: FoldersPage(
        helper: helper,
        rosterBuilder: (_) => DirectoryPage(helper: helper),
      ),
    );
  }
}

class DirectoryPage extends StatefulWidget {
  final DatabaseHelper helper;

  const DirectoryPage({super.key, required this.helper});

  @override
  State<DirectoryPage> createState() => _DirectoryPageState();
}

class _DirectoryPageState extends State<DirectoryPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  List<Map<String, dynamic>> _rows = [];

  bool _loading = true;
  bool _busy = false;

  String? _errorMessage;
  String? _feedbackMessage;

  int? _selectedId;

  bool get _isEditing => _selectedId != null;

  @override
  void initState() {
    super.initState();
    _loadRows();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  Future<void> _loadRows() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _errorMessage = null;
      });
    }

    try {
      final rows = await widget.helper.queryAllRows();
      final count = await widget.helper.queryRowCount();

      if (!mounted) return;

      setState(() {
        _rows = rows;
        _loading = false;
        _feedbackMessage = 'Loaded $count guest(s).';
      });
    } catch (error, stackTrace) {
      debugPrint('Load failed: $error\n$stackTrace');

      if (!mounted) return;

      setState(() {
        _loading = false;
        _errorMessage = 'Could not load the guest roster.';
      });
    }
  }

  String? _validateName(String? value) {
    final name = value?.trim() ?? '';

    if (name.isEmpty) {
      return 'Please enter a guest name.';
    }

    return null;
  }

  String? _validateAge(String? value) {
    final text = value?.trim() ?? '';

    final age = int.tryParse(text);

    if (age == null) {
      return 'Enter a whole number.';
    }

    if (age < 0 || age > 130) {
      return 'Age must be between 0 and 130.';
    }

    return null;
  }

  Future<void> _saveGuest() async {
    if (_busy) return;

    final valid = _formKey.currentState?.validate() ?? false;

    if (!valid) return;

    final name = _nameController.text.trim();
    final age = int.parse(_ageController.text.trim());

    setState(() {
      _busy = true;
      _errorMessage = null;
    });

    try {
      if (_isEditing) {
        final selectedId = _selectedId!;

        final updated = await widget.helper.update({
          DatabaseHelper.columnId: selectedId,
          DatabaseHelper.columnName: name,
          DatabaseHelper.columnAge: age,
        });

        if (updated == 0) {
          if (!mounted) return;

          setState(() {
            _feedbackMessage = 'Guest ID $selectedId was not found.';
          });

          await _refreshAfterAction();
          return;
        }

        if (!mounted) return;

        setState(() {
          _feedbackMessage = 'Updated guest ID $selectedId.';
        });
      } else {
        final id = await widget.helper.insert({
          DatabaseHelper.columnName: name,
          DatabaseHelper.columnAge: age,
        });

        if (!mounted) return;

        setState(() {
          _feedbackMessage = 'Added guest with ID $id.';
        });
      }

      _clearForm();

      await _refreshAfterAction();
    } catch (error, stackTrace) {
      debugPrint('Save failed: $error\n$stackTrace');

      if (!mounted) return;

      setState(() {
        _errorMessage = 'Could not save the guest. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  Future<void> _refreshAfterAction() async {
    try {
      final rows = await widget.helper.queryAllRows();
      final count = await widget.helper.queryRowCount();

      if (!mounted) return;

      setState(() {
        _rows = rows;
        _feedbackMessage = '${_feedbackMessage ?? ''} Record count: $count.';
      });
    } catch (error, stackTrace) {
      debugPrint('Refresh after action failed: $error\n$stackTrace');

      if (!mounted) return;

      setState(() {
        _errorMessage = 'Saved, but refresh failed. Please press Refresh.';
      });
    }
  }

  void _startEdit(Map<String, dynamic> row) {
    if (_busy) return;

    setState(() {
      _selectedId = row[DatabaseHelper.columnId] as int;
      _nameController.text = row[DatabaseHelper.columnName].toString();
      _ageController.text = row[DatabaseHelper.columnAge].toString();
      _feedbackMessage = 'Editing guest ID $_selectedId.';
    });
  }

  void _clearForm() {
    _nameController.clear();
    _ageController.clear();

    if (mounted) {
      setState(() {
        _selectedId = null;
      });
    }
  }

  void _cancelEdit() {
    if (_busy) return;

    _clearForm();

    setState(() {
      _feedbackMessage = 'Edit cancelled. No changes were saved.';
    });
  }

  Future<void> _deleteGuest(Map<String, dynamic> row) async {
    if (_busy) return;

    final id = row[DatabaseHelper.columnId] as int;
    final name = row[DatabaseHelper.columnName].toString();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete guest?'),
          content: Text('Delete guest ID $id, $name?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (!mounted) return;

    if (confirmed != true) {
      if (!mounted) return;

      setState(() {
        _feedbackMessage = 'Delete cancelled. Nothing was removed.';
      });

      return;
    }

    setState(() {
      _busy = true;
      _errorMessage = null;
    });

    try {
      final deleted = await widget.helper.delete(id);

      if (deleted == 0) {
        if (!mounted) return;

        setState(() {
          _feedbackMessage = 'Guest ID $id was not found.';
        });

        await _loadRows();
        return;
      }

      if (_selectedId == id) {
        _clearForm();
      }

      final rows = await widget.helper.queryAllRows();
      final count = await widget.helper.queryRowCount();

      if (!mounted) return;

      setState(() {
        _rows = rows;
        _feedbackMessage = 'Deleted guest ID $id. Record count: $count.';
      });
    } catch (error, stackTrace) {
      debugPrint('Delete failed: $error\n$stackTrace');

      if (!mounted) return;

      setState(() {
        _errorMessage = 'Could not delete the guest.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Fall Festival Roster')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _nameController,
                    enabled: !_busy,
                    decoration: const InputDecoration(
                      labelText: 'Guest name',
                      border: OutlineInputBorder(),
                    ),
                    validator: _validateName,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _ageController,
                    enabled: !_busy,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Age',
                      border: OutlineInputBorder(),
                    ),
                    validator: _validateAge,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _busy ? null : _saveGuest,
                  child: Text(_isEditing ? 'Save' : 'Add'),
                ),
                OutlinedButton(
                  onPressed: _busy || !_isEditing ? null : _cancelEdit,
                  child: const Text('Cancel Edit'),
                ),
                OutlinedButton(
                  onPressed: _busy ? null : _loadRows,
                  child: const Text('Refresh'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Record count: ${_rows.length}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (_feedbackMessage != null) ...[
              const SizedBox(height: 8),
              Text(_feedbackMessage!),
            ],
            if (_errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 12),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _rows.isEmpty
                  ? const Center(child: Text('No festival guests yet'))
                  : ListView.builder(
                      itemCount: _rows.length,
                      itemBuilder: (context, index) {
                        final row = _rows[index];

                        final id = row[DatabaseHelper.columnId];
                        final name = row[DatabaseHelper.columnName];
                        final age = row[DatabaseHelper.columnAge];

                        return Card(
                          child: ListTile(
                            title: Text('$name, age $age'),
                            subtitle: Text('ID: $id'),
                            trailing: Wrap(
                              spacing: 4,
                              children: [
                                IconButton(
                                  onPressed: _busy
                                      ? null
                                      : () => _startEdit(row),
                                  icon: const Icon(Icons.edit),
                                  tooltip: 'Edit',
                                ),
                                IconButton(
                                  onPressed: _busy
                                      ? null
                                      : () => _deleteGuest(row),
                                  icon: const Icon(Icons.delete),
                                  tooltip: 'Delete',
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
