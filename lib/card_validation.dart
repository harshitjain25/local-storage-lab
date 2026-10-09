const cardSuits = ['Hearts', 'Diamonds', 'Clubs', 'Spades'];
String? validateTitle(String? value) =>
    (value?.trim().isEmpty ?? true) ? 'Enter a title.' : null;
String suitSymbol(String suit) => switch (suit) {
  'Hearts' => '♥',
  'Diamonds' => '♦',
  'Clubs' => '♣',
  'Spades' => '♠',
  _ => '?',
};
