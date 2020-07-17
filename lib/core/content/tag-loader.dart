import '../api/api.dart';
import '../api/types.dart';
import '../parsers/types/module.dart';

class TagLoader {
  final _api;
  final String path;
  final TagListType tagListType;

  TagLoader({
    this.path,
    this.tagListType = TagListType.BEST,
    String prefix,
  }) : _api = prefix == null ? Api() : Api.withPrefix(prefix);

  final List<ContentPage<ExtendedTag>> _pages = [];
  final List<ExtendedTag> _tags = [];

  bool get complete {
    return (_pages.last?.isLast ?? false) || _complete;
  }

  List<ExtendedTag> get tags {
    return _tags;
  }

  ContentPage get firstPage => _pages.first;

  bool _complete = false;

  destroy() {
    _complete = true;
  }

  Future<List<ExtendedTag>> load() async {
    final page = await _api.loadMainTag(path, tagListType);
    _pages.add(page);
    _tags.addAll(page.content);
    return page.content;
  }

  void reset() {
    _pages.clear();
    _tags.clear();
    _complete = false;
  }

  Future<List<ExtendedTag>> loadNext() async {
    if (_pages.last.isLast || _complete) {
      return [];
    }
    int id = _pages.last.id + 1;
    final page = await _api.loadMainTagByPageId(id, path, tagListType);
    if (page.id == _pages.last.id) {
      _complete = true;
      return [];
    }
    _pages.add(page);
    _tags.addAll(page.content);

    return page.content;
  }
}