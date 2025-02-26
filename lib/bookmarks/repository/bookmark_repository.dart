import 'package:hive/hive.dart';
import 'package:otzaria/bookmarks/models/bookmark.dart';

class BookmarkRepository {
  final Box<dynamic> _box = Hive.box(name: 'bookmarks');

  List<Bookmark> loadBookmarks() {
    try {
      final List<dynamic> rawBookmarks = _box.get('key-bookmarks') ?? [];
      return rawBookmarks.map((e) => Bookmark.fromJson(e)).toList();
    } catch (e) {
      print('error loading bookmarks from disk: $e');
      _box.put('key-bookmarks', []);
      return [];
    }
  }

  Future<void> saveBookmarks(List<Bookmark> bookmarks) async {
    return _box.put('key-bookmarks', bookmarks);
  }

  Future<void> clearBookmarks() async {
    return _box.clear();
  }
}
