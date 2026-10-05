import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offline_notes/data/remote/post.dart';
import 'package:offline_notes/data/repositories/post_repository.dart';
import 'package:offline_notes/providers/offline_providers.dart';
import 'package:offline_notes/providers/post_providers.dart';

class FakePostRepository extends PostRepository {
  FakePostRepository(this.cached)
    : super(openDb: () => throw UnimplementedError());
  final List<Post> cached;
  final response = Completer<List<Post>>();
  int requests = 0;
  @override
  Future<List<Post>> readCachedPosts() async => cached;
  @override
  Future<List<Post>> fetchAndCache() {
    requests++;
    return response.future;
  }
}

void main() {
  const post = Post(id: 1, title: 'Cache SQLite', body: 'Tersimpan');
  test(
    'cache appears before network and remains after refresh failure',
    () async {
      final repo = FakePostRepository([post]);
      final container = ProviderContainer(
        overrides: [postRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);
      expect(
        (await container.read(postsProvider.future)).single.title,
        post.title,
      );
      expect(repo.requests, 1);
      repo.response.completeError(StateError('airplane mode'));
      await Future<void>.delayed(Duration.zero);
      expect(
        container.read(postsProvider).requireValue.single.title,
        post.title,
      );
    },
  );
  test('forced offline reads cache without network', () async {
    final repo = FakePostRepository([post]);
    final container = ProviderContainer(
      overrides: [postRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);
    container.read(forceOfflineProvider.notifier).toggle();
    expect((await container.read(postsProvider.future)).length, 1);
    expect(repo.requests, 0);
  });
}
