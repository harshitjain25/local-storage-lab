import 'package:flutter/material.dart';

import '../database_helper.dart';
import '../models/card.dart' as model;
import '../models/folder.dart';
import '../card_validation.dart';
import 'card_form.dart';

class CardsPage extends StatefulWidget {
  final DatabaseHelper helper;
  final Folder folder;
  const CardsPage({super.key, required this.helper, required this.folder});
  @override
  State<CardsPage> createState() => _CardsPageState();
}

class _CardsPageState extends State<CardsPage> {
  List<model.Card> _cards = [];
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
      final cards = await widget.helper.getCards(widget.folder.id!);
      if (!mounted) return;
      setState(() {
        _cards = cards;
        _loading = false;
        _error = null;
      });
    } catch (error) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Could not load cards. Please retry.';
        });
      }
    }
  }

  Future<void> _form([model.Card? card]) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CardForm(
          helper: widget.helper,
          folderId: widget.folder.id!,
          card: card,
        ),
      ),
    );
    if (mounted) await _load();
  }

  Future<void> _delete(model.Card card) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete card?'),
        content: Text('Delete "${card.title}" (ID ${card.id})?'),
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
      final affected = await widget.helper.deleteCard(card.id!);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            affected == 0
                ? 'Card no longer exists.'
                : 'Deleted card ID ${card.id}.',
          ),
        ),
      );
      await _load();
    } catch (error) {
      if (mounted) {
        setState(() => _error = 'Could not delete card. Please retry.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.folder.name),
      actions: [
        IconButton(
          onPressed: _busy ? null : _load,
          icon: const Icon(Icons.refresh),
          tooltip: 'Refresh',
        ),
      ],
    ),
    floatingActionButton: FloatingActionButton(
      onPressed: _busy || _loading ? null : () => _form(),
      tooltip: 'Add card',
      child: const Icon(Icons.add),
    ),
    body: Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            'Folder ID: ${widget.folder.id} • ${_cards.length} card(s)',
          ),
        ),
        if (_error != null) Text(_error!),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _cards.isEmpty
              ? const Center(
                  child: Text('No cards in this folder. Add a card to start.'),
                )
              : ListView.builder(
                  itemCount: _cards.length,
                  itemBuilder: (context, index) {
                    final card = _cards[index];
                    return Card(
                      key: ValueKey(card.id),
                      child: ListTile(
                        leading: CardImage(card: card),
                        title: Text(card.title),
                        subtitle: Text(
                          'Card ID: ${card.id} • Folder ID: ${card.folderId}\n${card.suit}\n${card.notes}',
                        ),
                        isThreeLine: true,
                        onTap: _busy ? null : () => _form(card),
                        trailing: Wrap(
                          children: [
                            IconButton(
                              onPressed: _busy ? null : () => _form(card),
                              icon: const Icon(Icons.edit),
                              tooltip: 'Edit card',
                            ),
                            IconButton(
                              onPressed: _busy ? null : () => _delete(card),
                              icon: const Icon(Icons.delete),
                              tooltip: 'Delete card',
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
  );
}

// References are bundled asset paths; missing assets never hide card data.
class CardImage extends StatelessWidget {
  final model.Card card;
  const CardImage({super.key, required this.card});
  @override
  Widget build(BuildContext context) {
    final placeholder = Center(
      child: Text(
        suitSymbol(card.suit),
        style: TextStyle(
          fontSize: 32,
          color: ['Hearts', 'Diamonds'].contains(card.suit)
              ? Colors.red
              : Colors.black,
        ),
      ),
    );
    final ref = card.imageRef?.trim();
    return SizedBox(
      width: 48,
      height: 48,
      child: ref == null || ref.isEmpty
          ? placeholder
          : Image.asset(
              ref,
              fit: BoxFit.contain,
              errorBuilder: (_, error, stackTrace) => placeholder,
            ),
    );
  }
}
