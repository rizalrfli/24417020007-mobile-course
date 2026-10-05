class Note {
  const Note({
    this.id,
    required this.title,
    this.body = '',
    required this.updatedAt,
    this.dirty = false,
    this.deleted = false,
  });

  final int? id;
  final String title;
  final String body;
  final DateTime updatedAt;
  final bool dirty;
  final bool deleted;

  Note copyWith({
    int? id,
    String? title,
    String? body,
    DateTime? updatedAt,
    bool? dirty,
    bool? deleted,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      updatedAt: updatedAt ?? this.updatedAt,
      dirty: dirty ?? this.dirty,
      deleted: deleted ?? this.deleted,
    );
  }

  Map<String, Object?> toMap() => {
    'id': id,
    'title': title,
    'body': body,
    'updated_at': _utcTimestamp(updatedAt),
    'dirty': dirty ? 1 : 0,
    'deleted': deleted ? 1 : 0,
  };

  static String _utcTimestamp(DateTime value) {
    final utc = value.toUtc();
    final seconds = utc.toIso8601String().split('.').first;
    return '$seconds.${utc.millisecond.toString().padLeft(3, '0')}${utc.microsecond.toString().padLeft(3, '0')}Z';
  }

  factory Note.fromMap(Map<String, Object?> map) {
    return Note(
      id: (map['id'] as num?)?.toInt(),
      title: map['title'] as String? ?? '',
      body: map['body'] as String? ?? '',
      updatedAt:
          DateTime.tryParse(map['updated_at'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      dirty: ((map['dirty'] as num?)?.toInt() ?? 0) == 1,
      deleted: ((map['deleted'] as num?)?.toInt() ?? 0) == 1,
    );
  }
}
