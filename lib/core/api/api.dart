import 'dart:io';

import 'package:dio/dio.dart';

import '../auth/auth.dart';
import '../common/types.dart';
import '../content/content-parser.dart';
import '../content/stats-parser.dart';
import '../content/tag-parser.dart';
import '../content/types/module.dart';
import '../content/user-parser.dart';
import '../http/session.dart';
import 'types.dart';

class Api {
  static final _api = Api._internal();
  static final _contentParser = ContentParser();
  static final _tagParser = TagParser();
  static final _userParser = UserParser();
  static final _sidebarParser = StatsParser();
  static final _session = Session();
  static final _auth = Auth();
  String _prefix = 'joy';

  factory Api() {
    return _api;
  }

  static Api withPrefix(String prefix) {
    final instance = Api._internal();
    instance._prefix = prefix + '.';
    return instance;
  }

  Api._internal();

  String _postTypeToString(PostListType type) {
    switch (type) {
      case PostListType.ALL:
        return '/all';
      case PostListType.GOOD:
        return '';
      case PostListType.BEST:
        return '/best';
      case PostListType.NEW:
        return '/new';
    }
    return null;
  }

  String _voteToString(VoteType type) {
    switch (type) {
      case VoteType.UP:
        return 'plus';
      case VoteType.DOWN:
        return 'minus';
    }
    return null;
  }

  String _tagTypeToString(TagListType type) {
    switch (type) {
      case TagListType.BEST:
        return '/rating';
      case TagListType.NEW:
        return '/subtags';
    }
    return null;
  }

  Future<Post> loadPost(int id) async {
    final res =
        await _session.get('http://${_prefix}reactor.cc/post/${id.toString()}');
    return _contentParser.parsePost(id, res.data);
  }

  Future<UserFull> loadUserPage(String link) async {
    final res = await _session.get('http://${_prefix}reactor.cc/user/$link');
    return _userParser.parse(res.data, link);
  }

  Future<ContentPage<Post>> _loadPage(String url) async {
    final res = await _session.get(url);
    final page = _contentParser.parsePage(res.data);
    if (_auth.authorized && !page.authorized) {
      _auth.logout();
    }
    return page;
  }

  Future<ContentPage<Post>> load(PostListType type) =>
      _loadPage('http://${_prefix}reactor.cc${_postTypeToString(type)}');

  Future<ContentPage<Post>> loadByPageId(int pageId, PostListType type) =>
      _loadPage(
        'http://${_prefix}reactor.cc${_postTypeToString(type)}/$pageId',
      );

  Future<ContentPage<Post>> loadTag(String tag, PostListType type) => _loadPage(
      'http://${_prefix}reactor.cc/tag/$tag${_postTypeToString(type)}');

  Future<ContentPage<Post>> loadTagByPageId(
          String tag, int pageId, PostListType type) =>
      _loadPage(
        'http://${_prefix}reactor.cc/tag/$tag${_postTypeToString(type)}/$pageId',
      );

  Future<ContentPage<Post>> loadUser(String username) =>
      _loadPage('http://${_prefix}reactor.cc/user/$username');

  Future<ContentPage<Post>> loadUserByPageId(String username, int pageId) =>
      _loadPage('http://${_prefix}reactor.cc/user/$username/$pageId');

  Future<ContentPage<Post>> loadSubscriptions() =>
      _loadPage('http://joyreactor.cc/subscriptions');

  Future<ContentPage<Post>> loadSubscriptionsByPageId(int id) =>
      _loadPage('http://joyreactor.cc/subscriptions/$id');

  Future<ContentPage<Post>> loadFavorite(String username) =>
      _loadPage('http://joyreactor.cc/user/$username/favorite');

  Future<ContentPage<Post>> loadFavoriteByPageId(String username, int id) =>
      _loadPage('http://joyreactor.cc/user/$username/favorite/$id');

  Future<List<ContentUnit>> loadComment(int id) async {
    final res =
        await _session.get('http://${_prefix}reactor.cc/post/comment/$id');
    return _contentParser.parseContent(res.data);
  }

  Future<List<PostComment>> loadComments(int id) async {
    final res =
        await _session.get('http://${_prefix}reactor.cc/post/comments/$id');
    return _contentParser.parseComments(res.data, id);
  }

  Future<void> setFavorite(int postId, bool state) {
    return _session.get(
        'http://${_prefix}reactor.cc/favorite/${state ? 'create' : 'delete'}/$postId?token=${_session.apiToken}');
  }

  Future<Pair<double, bool>> votePost(int id, VoteType type) async {
    final res = await _session.get(
        'http://joyreactor.cc/post_vote/add/$id/${_voteToString(type)}?token=${_session.apiToken}&abyss=0');
    final str = res.data.toString().replaceFirst('<span>', '');
    return Pair(double.tryParse(str.substring(0, str.indexOf('<'))),
        res.data.toString().indexOf('vote-plus') != -1);
  }

  Future<double> voteComment(int id, VoteType type) async {
    final res = await _session.get(
        'http://joyreactor.cc/comment_vote/add/$id/${_voteToString(type)}?token=${_session.apiToken}');
    final str = res.data.toString().replaceFirst('<span>', '');
    return double.tryParse(str.substring(0, str.indexOf('<')));
  }

  Future<void> setTagFavorite(int id, bool state) async {
    return _session.get(
      'http://${_prefix}reactor.cc/favorite/${state ? 'create' : 'delete'}Blog/$id${state ? '/1' : ''}?token=${_session.apiToken}',
    );
  }

  Future<void> setTagBlock(int id, bool state) async {
    return _session.get(
        'http://${_prefix}reactor.cc/favorite/${state ? 'create' : 'delete'}Blog/$id${state ? '/-1' : ''}?token=${_session.apiToken}');
  }

  Future<Post> loadPostContent(int id) async {
    final res = await _session.get(
        'http://${_prefix}reactor.cc/hidden/delete/$id?token=${_session.apiToken}');
    return _contentParser.parseInner(id, res.data);
  }

  Future<ContentPage<ExtendedTag>> loadMainTag(
      String tag, TagListType type) async {
    final res = await _session
        .get('http://${_prefix}reactor.cc/tag/$tag${_tagTypeToString(type)}');
    return _tagParser.parsePage(res.data);
  }

  Future<ContentPage<ExtendedTag>> loadMainTagByPageId(
      int id, String tag, TagListType type) async {
    final res = await _session.get(
        'http://${_prefix}reactor.cc/tag/$tag${_tagTypeToString(type)}/$id');
    return _tagParser.parsePage(res.data);
  }

  Future<Stats> loadSidebar() async {
    final res = await _session.get('http://joyreactor.cc/search');
    return _sidebarParser.parse(res.data);
  }

  Future<void> createComment(
    int postId,
    int parentId,
    String text,
    File picture, {
    ProgressCallback onSendProgress,
  }) async {
    final file =
        picture != null ? (await MultipartFile.fromFile(picture.path)) : null;

    final formData = FormData.fromMap({
      'parent_id': parentId,
      'post_id': postId,
      'token': _session.apiToken,
      'comment_text': text,
      'comment_picture': file,
      'comment_picture_url': null,
    });

    return _session.post(
      'http://joyreactor.cc/post_comment/create',
      formData,
      onSendProgress: onSendProgress,
    );
  }

  Future<Response> deleteComment(int commentId) {
    return _session.get(
      'http://joyreactor.cc/post_comment/delete/$commentId?token=${_session.apiToken}',
    );
  }
}
