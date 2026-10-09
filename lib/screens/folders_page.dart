import 'package:flutter/material.dart';

import '../database_helper.dart';
import '../models/folder.dart';
import 'cards_page.dart';

class FoldersPage extends StatefulWidget {
  final DatabaseHelper helper;
  final WidgetBuilder rosterBuilder;
  const FoldersPage({
    super.key,
    required this.helper,
    required this.rosterBuilder,
  });
  @override
  State<FoldersPage> createState() => _FoldersPageState();
}

class _FoldersPageState extends State<FoldersPage> {
  List<FolderWithCount> _folders = [];
  bool _loading = true;
  bool _busy = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final folders = await widget.helper.getFoldersWithCounts();
      if (!mounted) return;
      setState(() {
        _folders = folders;
        _loading = false;
        _error = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Could not load folders. Please retry.';
      });
    }
  }

  Future<void> _add() async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => _AddFolderDialog(helper: widget.helper),
    );
    if (!mounted) return;
    if (saved == true) await _load();
  }

  Future<void> _delete(Folder folder) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete folder?'),
        content: Text(
          'Delete "${folder.name}" (ID ${folder.id}) and all its cards?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    setState(() => _busy = true);
    try {
      final affected = await widget.helper.deleteFolder(folder.id!);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            affected == 0
                ? 'Folder no longer exists.'
                : 'Deleted folder ID ${folder.id}.',
          ),
        ),
      );
      await _load();
    } catch (error) {
      if (mounted) {
        setState(() => _error = 'Could not delete folder. Please retry.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Card catalogue'),
      actions: [
        TextButton(
          onPressed: _busy
              ? null
              : () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: widget.rosterBuilder),
                ),
          child: const Text('Part I roster'),
        ),
        IconButton(
          onPressed: _busy ? null : _load,
          icon: const Icon(Icons.refresh),
          tooltip: 'Refresh',
        ),
      ],
    ),
    floatingActionButton: FloatingActionButton(
      onPressed: _busy || _loading ? null : _add,
      tooltip: 'Add folder',
      child: const Icon(Icons.create_new_folder),
    ),
    body: Column(
      children: [
        if (_error != null)
          Padding(padding: const EdgeInsets.all(16), child: Text(_error!)),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _folders.isEmpty
              ? const Center(
                  child: Text('No folders yet. Add a folder to start.'),
                )
              : ListView.builder(
                  itemCount: _folders.length,
                  itemBuilder: (context, index) {
                    final entry = _folders[index];
                    return ListTile(
                      key: ValueKey(entry.folder.id),
                      title: Text(entry.folder.name),
                      subtitle: Text(
                        'Folder ID: ${entry.folder.id} • ${entry.count} card(s)',
                      ),
                      trailing: IconButton(
                        onPressed: _busy ? null : () => _delete(entry.folder),
                        icon: const Icon(Icons.delete),
                        tooltip: 'Delete folder',
                      ),
                      onTap: _busy
                          ? null
                          : () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => CardsPage(
                                    helper: widget.helper,
                                    folder: entry.folder,
                                  ),
                                ),
                              );
                              if (mounted) await _load();
                            },
                    );
                  },
                ),
        ),
      ],
    ),
  );
}

class _AddFolderDialog extends StatefulWidget {
  final DatabaseHelper helper;
  const _AddFolderDialog({required this.helper});
  @override
  State<_AddFolderDialog> createState() => _AddFolderDialogState();
}

class _AddFolderDialogState extends State<_AddFolderDialog> {
  final _name = TextEditingController();
  final _form = GlobalKey<FormState>();
  bool _busy = false;
  String? _error;
  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_busy || !_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.helper.insertFolder(
        Folder(
          name: _name.text.trim(),
          createdAt: DateTime.now().toUtc().toIso8601String(),
        ),
      );
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = 'Could not save. Use a unique folder name and retry.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: AlertDialog(
      title: const Text('Add folder'),
      content: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _name,
              enabled: !_busy,
              decoration: const InputDecoration(labelText: 'Folder name'),
              validator: (value) => (value?.trim().isEmpty ?? true)
                  ? 'Enter a folder name.'
                  : null,
            ),
            if (_error != null) Text(_error!),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _busy ? null : _save,
          child: Text(_busy ? 'Saving…' : 'Save'),
        ),
      ],
    ),
  );
}
