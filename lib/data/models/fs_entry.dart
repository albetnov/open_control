class FsEntry {
  const FsEntry({
    required this.name,
    required this.isDir,
    required this.size,
    required this.modTime,
  });

  final String name;
  final bool isDir;
  final int size;
  final DateTime modTime;

  factory FsEntry.fromJson(Map<String, dynamic> json) => FsEntry(
    name: json['name'] as String,
    isDir: json['isDir'] as bool,
    size: json['size'] as int,
    modTime: DateTime.parse(json['modTime'] as String),
  );
}
