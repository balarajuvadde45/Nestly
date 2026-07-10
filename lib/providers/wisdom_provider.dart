import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../data/wisdom_mock_data.dart';
import '../models/wisdom_post.dart';
import '../services/api_client.dart';

class WisdomProvider extends ChangeNotifier {
  WisdomProvider(this._api);

  final ApiClient _api;
  final _uuid = const Uuid();

  final List<WisdomPost> _posts = List.from(WisdomMockData.posts);
  WisdomTopic? _topicFilter;
  WisdomPostType? _typeFilter;
  String _query = '';
  bool _loading = false;
  String? _error;

  List<WisdomPost> get posts {
    var list = List<WisdomPost>.from(_posts);
    if (_topicFilter != null) {
      list = list.where((p) => p.topic == _topicFilter).toList();
    }
    if (_typeFilter != null) {
      list = list.where((p) => p.type == _typeFilter).toList();
    }
    if (_query.trim().isNotEmpty) {
      final q = _query.toLowerCase();
      list = list
          .where((p) =>
              p.title.toLowerCase().contains(q) ||
              p.body.toLowerCase().contains(q) ||
              p.tags.any((t) => t.toLowerCase().contains(q)) ||
              p.authorName.toLowerCase().contains(q))
          .toList();
    }
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  WisdomTopic? get topicFilter => _topicFilter;
  WisdomPostType? get typeFilter => _typeFilter;
  String get query => _query;
  bool get loading => _loading;
  String? get error => _error;

  int get elderPostCount => _posts.where((p) => p.isElder).length;
  int get openQuestions =>
      _posts.where((p) => p.type == WisdomPostType.question).length;

  void setTopic(WisdomTopic? t) {
    _topicFilter = t;
    notifyListeners();
  }

  void setType(WisdomPostType? t) {
    _typeFilter = t;
    notifyListeners();
  }

  void setQuery(String q) {
    _query = q;
    notifyListeners();
  }

  void clearFilters() {
    _topicFilter = null;
    _typeFilter = null;
    _query = '';
    notifyListeners();
  }

  WisdomPost? getById(String id) {
    try {
      return _posts.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> loadFromApi() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final online = await _api.healthCheck();
      if (!online) {
        _loading = false;
        notifyListeners();
        return;
      }
      final res = await _api.get('/api/wisdom/posts');
      final list = res['posts'] as List?;
      if (list != null && list.isNotEmpty) {
        // Keep local answers rich; merge by id if API shape matches later
        // For now API may return simplified posts — only replace if parseable
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void addPost({
    required String authorName,
    required int authorAge,
    required bool isElder,
    required String title,
    required String body,
    required WisdomPostType type,
    required WisdomTopic topic,
    List<String> tags = const [],
  }) {
    final post = WisdomPost(
      id: 'w_${_uuid.v4().substring(0, 8)}',
      authorName: authorName,
      authorAge: authorAge,
      isElder: isElder,
      title: title,
      body: body,
      type: type,
      topic: topic,
      createdAt: DateTime.now(),
      tags: tags,
    );
    _posts.insert(0, post);
    notifyListeners();

    // Best-effort API sync
    _api.post('/api/wisdom/posts', body: {
      'authorName': authorName,
      'authorAge': authorAge,
      'isElder': isElder,
      'title': title,
      'body': body,
      'type': type.name,
      'topic': topic.name,
      'tags': tags,
    }).catchError((_) => <String, dynamic>{});
  }

  void addAnswer({
    required String postId,
    required String authorName,
    required int authorAge,
    required bool isFromElder,
    required String body,
  }) {
    final i = _posts.indexWhere((p) => p.id == postId);
    if (i < 0) return;
    final post = _posts[i];
    final answer = WisdomAnswer(
      id: 'a_${_uuid.v4().substring(0, 8)}',
      postId: postId,
      authorName: authorName,
      authorAge: authorAge,
      body: body,
      createdAt: DateTime.now(),
      isFromElder: isFromElder,
    );
    final answers = [...post.answers, answer];
    _posts[i] = WisdomPost(
      id: post.id,
      authorName: post.authorName,
      authorAge: post.authorAge,
      isElder: post.isElder,
      title: post.title,
      body: post.body,
      type: post.type,
      topic: post.topic,
      createdAt: post.createdAt,
      helpfulCount: post.helpfulCount,
      replyCount: answers.length,
      answers: answers,
      tags: post.tags,
    );
    notifyListeners();
  }

  void markHelpful(String postId) {
    final i = _posts.indexWhere((p) => p.id == postId);
    if (i < 0) return;
    final p = _posts[i];
    _posts[i] = WisdomPost(
      id: p.id,
      authorName: p.authorName,
      authorAge: p.authorAge,
      isElder: p.isElder,
      title: p.title,
      body: p.body,
      type: p.type,
      topic: p.topic,
      createdAt: p.createdAt,
      helpfulCount: p.helpfulCount + 1,
      replyCount: p.replyCount,
      answers: p.answers,
      tags: p.tags,
    );
    notifyListeners();
  }
}
