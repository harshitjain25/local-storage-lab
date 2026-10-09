import 'package:flutter/material.dart';

import '../database_helper.dart';
import '../models/card.dart' as model;
import '../models/folder.dart';
import '../card_validation.dart';

class CardForm extends StatefulWidget {
  final DatabaseHelper helper;
  final int folderId;
  final model.Card? card;
  const CardForm({
    super.key,
    required this.helper,
    required this.folderId,
    this.card,
  });
  @override
  State<CardForm> createState() => _CardFormState();
}

class _CardFormState extends State<CardForm> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _notes;
  late final TextEditingController _image;
  late int _folderId;
  String? _suit;
  List<Folder> _folders = [];
  bool _loading = true;
  bool _busy = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.card?.title ?? '');
    _notes = TextEditingController(text: widget.card?.notes ?? '');
    _image = TextEditingController(text: widget.card?.imageRef ?? '');
    _folderId = widget.card?.folderId ?? widget.folderId;
    _suit = widget.card?.suit;
    _loadFolders();
  }

  Future<void> _loadFolders() async {
    try {
      final entries = await widget.helper.getFoldersWithCounts();
      if (!mounted) return;
      setState(() {
        _folders = entries.map((e) => e.folder).toList();
        _loading = false;
        _error = null;
      });
    } catch (error) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Could not load folders. Please retry.';
        });
      }
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _notes.dispose();
    _image.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_busy || !_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final image = _image.text.trim();
    final card = model.Card(
      id: widget.card?.id,
      title: _title.text.trim(),
      suit: _suit!,
      notes: _notes.text,
      imageRef: image.isEmpty ? null : image,
      folderId: _folderId,
    );
    try {
      final result = widget.card == null
          ? await widget.helper.insertCard(card)
          : await widget.helper.updateCard(card);
      if (result == 0) throw StateError('Card no longer exists.');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Saved card ID ${widget.card?.id ?? result}.')),
      );
      Navigator.pop(context, true);
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = 'Could not save the card. Your input is kept. Check the folder and retry.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: Scaffold(
      appBar: AppBar(
        title: Text(
          widget.card == null ? 'Add card' : 'Edit card ID ${widget.card!.id}',
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _form,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  TextFormField(
                    controller: _title,
                    enabled: !_busy,
                    decoration: const InputDecoration(labelText: 'Title'),
                    validator: validateTitle,
                  ),
                  DropdownButtonFormField<int>(
                    initialValue: _folders.any((f) => f.id == _folderId)
                        ? _folderId
                        : null,
                    decoration: const InputDecoration(labelText: 'Folder'),
                    items: _folders
                        .map(
                          (f) => DropdownMenuItem(
                            value: f.id,
                            child: Text('${f.name} (ID ${f.id})'),
                          ),
                        )
                        .toList(),
                    onChanged: _busy
                        ? null
                        : (id) {
                            if (id != null) _folderId = id;
                          },
                    validator: (id) =>
                        id == null || !_folders.any((f) => f.id == id)
                        ? 'Select a valid folder.'
                        : null,
                  ),
                  DropdownButtonFormField<String>(
                    initialValue: cardSuits.contains(_suit) ? _suit : null,
                    decoration: const InputDecoration(labelText: 'Suit'),
                    items: cardSuits
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: _busy ? null : (suit) => _suit = suit,
                    validator: (suit) =>
                        !cardSuits.contains(suit) ? 'Select a suit.' : null,
                  ),
                  TextFormField(
                    controller: _notes,
                    enabled: !_busy,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Notes (optional)',
                    ),
                  ),
                  TextFormField(
                    controller: _image,
                    enabled: !_busy,
                    decoration: const InputDecoration(
                      labelText: 'Bundled asset image reference (optional)',
                    ),
                  ),
                  if (_error != null)
                    Text(_error!, style: const TextStyle(color: Colors.red)),
                  TextButton(
                    onPressed: _busy ? null : _loadFolders,
                    child: const Text('Reload folders'),
                  ),
                  FilledButton(
                    onPressed: _busy ? null : _save,
                    child: Text(_busy ? 'Saving…' : 'Save'),
                  ),
                  TextButton(
                    onPressed: _busy ? null : () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ],
              ),
            ),
    ),
  );
}
