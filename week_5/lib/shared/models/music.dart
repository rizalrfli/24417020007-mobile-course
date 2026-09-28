class Artist {
  final String id;
  final String name;
  final String? imageUrl;
  final bool isDemo;

  const Artist({
    required this.id,
    required this.name,
    this.imageUrl,
    this.isDemo = false,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Artist &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name;

  @override
  int get hashCode => id.hashCode ^ name.hashCode;
}

class Album {
  final String id;
  final String title;
  final String? coverUrl;
  final int? releaseYear;

  const Album({
    required this.id,
    required this.title,
    String? coverUrl,
    String? cover,
    this.releaseYear,
  }) : coverUrl = coverUrl ?? cover;

  String? get cover => coverUrl;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Album &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title;

  @override
  int get hashCode => id.hashCode ^ title.hashCode;
}

class Song {
  final String id;
  final String title;
  final Artist artist;
  final Album? album;
  final String? coverUrl;
  final int? durationSeconds;
  final String? genre;
  final int? releaseYear;
  final bool isDemo;

  const Song({
    required this.id,
    required this.title,
    required this.artist,
    this.album,
    String? coverUrl,
    String? cover,
    this.durationSeconds,
    this.genre,
    this.releaseYear,
    this.isDemo = false,
  }) : coverUrl = coverUrl ?? cover;

  String? get cover => coverUrl;

  Duration? get duration =>
      durationSeconds == null ? null : Duration(seconds: durationSeconds!);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Song && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class LyricLine {
  final Duration startTime;
  final Duration? endTime;
  final String text;

  const LyricLine({
    required this.startTime,
    required this.text,
    this.endTime,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LyricLine &&
          runtimeType == other.runtimeType &&
          startTime == other.startTime &&
          text == other.text;

  @override
  int get hashCode => startTime.hashCode ^ text.hashCode;
}

class Lyrics {
  final String? text;
  final String? attribution;
  final bool isDemo;
  final List<LyricLine>? timedLines;

  const Lyrics({
    this.text,
    this.attribution,
    this.isDemo = false,
    this.timedLines,
  });

  List<LyricLine> get lines {
    if (timedLines != null && timedLines!.isNotEmpty) {
      return timedLines!;
    }
    final raw = text?.trim();
    if (raw == null || raw.isEmpty) return const [];

    final rawLines = raw.split('\n');
    final result = <LyricLine>[];
    var currentSeconds = 8;
    for (final rawLine in rawLines) {
      final trimmed = rawLine.trim();
      if (trimmed.isEmpty) {
        result.add(LyricLine(
          startTime: Duration(seconds: currentSeconds),
          text: '',
        ));
      } else {
        result.add(LyricLine(
          startTime: Duration(seconds: currentSeconds),
          text: trimmed,
        ));
        currentSeconds += 6;
      }
    }
    return result;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Lyrics &&
          runtimeType == other.runtimeType &&
          text == other.text &&
          attribution == other.attribution;

  @override
  int get hashCode => (text?.hashCode ?? 0) ^ (attribution?.hashCode ?? 0);
}

class HomeFeed {
  final List<Song> popular;
  final List<Song> recommended;
  final List<Artist> artists;
  final bool isDemo;

  const HomeFeed({
    this.popular = const [],
    this.recommended = const [],
    this.artists = const [],
    this.isDemo = false,
  });
}
