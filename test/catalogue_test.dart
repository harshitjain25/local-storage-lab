import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_storage_lab/models/card.dart' as model;
import 'package:local_storage_lab/models/folder.dart';
import 'package:local_storage_lab/card_validation.dart';
import 'package:local_storage_lab/database_helper.dart';
import 'package:local_storage_lab/screens/card_form.dart';
import 'package:local_storage_lab/screens/cards_page.dart';

class MemoryHelper extends DatabaseHelper {
  int writes = 0;
  bool failWrite = false;
  model.Card? saved;
  @override
  Future<List<FolderWithCount>> getFoldersWithCounts() async => [
    const FolderWithCount(
      folder: Folder(id: 42, name: 'A', createdAt: 'date'),
      count: 0,
    ),
  ];
  @override
  Future<int> insertCard(model.Card card) async {
    writes++;
    if (failWrite) throw StateError('Write failed');
    saved = card;
    return 91;
  }

  @override
  Future<int> updateCard(model.Card card) => insertCard(card);
}

void main() {
  test('Folder map round trip keeps actual ID and timestamp', () {
    const folder = Folder(id: 42, name: 'A', createdAt: '2026-10-09');
    expect(Folder.fromMap(folder.toMap()).toMap(), folder.toMap());
  });
  test('Card map round trip keeps all fields and nullable image', () {
    for (final image in [null, 'assets/card.png']) {
      final card = model.Card(
        id: 91,
        title: 'Ace',
        suit: 'Spades',
        notes: 'Example',
        imageRef: image,
        folderId: 42,
      );
      expect(model.Card.fromMap(card.toMap()).toMap(), card.toMap());
    }
  });
  test('Title validation and all suit symbols', () {
    expect(validateTitle(null), isNotNull);
    expect(validateTitle('  '), isNotNull);
    expect(validateTitle(' Ace '), isNull);
    expect(cardSuits.map(suitSymbol), ['♥', '♦', '♣', '♠']);
  });
  testWidgets(
    'Blank title rejected; valid save trims title and uses real folder ID',
    (tester) async {
      final helper = MemoryHelper();
      await tester.pumpWidget(
        MaterialApp(
          home: CardForm(
            helper: helper,
            folderId: 42,
            card: const model.Card(
              id: 91,
              title: ' ',
              suit: 'Hearts',
              folderId: 42,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pumpAndSettle();
      expect(find.text('Enter a title.'), findsOneWidget);
      expect(helper.writes, 0);
      await tester.enterText(find.byType(TextFormField).first, ' Ace ');
      helper.failWrite = true;
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pumpAndSettle();
      expect(find.text(' Ace '), findsOneWidget);
      expect(find.textContaining('Your input is kept'), findsOneWidget);
      helper.failWrite = false;
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pumpAndSettle();
      expect(helper.saved!.title, 'Ace');
      expect(helper.saved!.id, 91);
      expect(helper.saved!.folderId, 42);
    },
  );
  testWidgets('Cancel edit writes nothing', (tester) async {
    final helper = MemoryHelper();
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CardForm(
                  helper: helper,
                  folderId: 42,
                  card: const model.Card(
                    id: 91,
                    title: 'Ace',
                    suit: 'Spades',
                    folderId: 42,
                  ),
                ),
              ),
            ),
            child: const Text('Open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'Changed');
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(helper.writes, 0);
    expect(find.text('Open'), findsOneWidget);
  });
  testWidgets('Null, empty and broken asset images show a suit placeholder', (
    tester,
  ) async {
    for (final ref in [null, '', 'missing.png']) {
      await tester.pumpWidget(
        MaterialApp(
          home: CardImage(
            card: model.Card(
              title: 'Ace',
              suit: 'Spades',
              folderId: 42,
              imageRef: ref,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('♠'), findsOneWidget);
    }
  });
}
