class Folder {
  final int? id;
  final String name;
  final String createdAt;
  const Folder({this.id, required this.name, required this.createdAt});
  factory Folder.fromMap(Map<String, Object?> map) => Folder(
    id: map['id'] as int?,
    name: map['name'] as String,
    createdAt: map['created_at'] as String,
  );
  Map<String, Object?> toMap() => {
    'id': id,
    'name': name,
    'created_at': createdAt,
  };
}

class FolderWithCount {
  final Folder folder;
  final int count;
  const FolderWithCount({required this.folder, required this.count});
}
