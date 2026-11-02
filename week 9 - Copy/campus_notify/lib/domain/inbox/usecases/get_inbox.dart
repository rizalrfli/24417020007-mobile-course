import 'package:campus_notify/domain/failures.dart';
import 'package:campus_notify/domain/inbox/inbox_item.dart';
import 'package:campus_notify/domain/inbox/inbox_repository.dart';

class GetInbox {
  const GetInbox(this._repository);

  final InboxRepository _repository;

  Future<({List<InboxItem> items, Failure? failure})> call() =>
      _repository.load();
}
