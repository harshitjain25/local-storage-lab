class Card {
  final int? id;
  final String title;
  final String suit;
  final String notes;
  final String? imageRef;
  final int folderId;
  const Card({
    this.id,
    required this.title,
    required this.suit,
    this.notes = '',
    this.imageRef,
    required this.folderId,
  });
  factory Card.fromMap(Map<String, Object?> map) => Card(
    id: map['id'] as int?,
    title: map['title'] as String,
    suit: map['suit'] as String,
    notes: map['notes'] as String,
    imageRef: map['image_ref'] as String?,
    folderId: map['folder_id'] as int,
  );
  Map<String, Object?> toMap() => {
    'id': id,
    'title': title,
    'suit': suit,
    'notes': notes,
    'image_ref': imageRef,
    'folder_id': folderId,
  };
}
