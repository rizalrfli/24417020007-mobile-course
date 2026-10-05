import 'package:dio/dio.dart';
import '../local/note.dart';

abstract interface class NoteRemote {
  Future<Note> upload(Note note);
}

class HttpNoteRemote implements NoteRemote {
  HttpNoteRemote({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: const String.fromEnvironment(
                'NOTES_API_URL',
                defaultValue: 'http://10.0.2.2:8080',
              ),
              connectTimeout: const Duration(seconds: 5),
              receiveTimeout: const Duration(seconds: 5),
              sendTimeout: const Duration(seconds: 5),
            ),
          );
  final Dio _dio;

  @override
  Future<Note> upload(Note note) async {
    final response = await _dio.put<Map<String, dynamic>>(
      '/notes/${note.id}',
      data: note.toMap(),
    );
    if (response.statusCode != 200 || response.data == null) {
      throw StateError('Server belum mengakui catatan');
    }
    final map = response.data!;
    if (map['id'] is! int ||
        map['title'] is! String ||
        map['body'] is! String ||
        map['updated_at'] is! String ||
        DateTime.tryParse(map['updated_at']) == null ||
        ![0, 1].contains(map['deleted'])) {
      throw const FormatException('ACK server tidak lengkap');
    }
    return Note.fromMap(map).copyWith(dirty: false);
  }
}
