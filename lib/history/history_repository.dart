import 'package:hive/hive.dart';
import 'package:otzaria/bookmarks/models/bookmark.dart';

class HistoryRepository {
  final Box<dynamic> _box = Hive.box(name: 'history');

  Future<void> saveHistory(List<Bookmark> history) async {
    _box.put('history', history.map((b) => b.toJson()).toList());
  }

  Future<List<Bookmark>> loadHistory() async {
    final historyJson = _box.get('history', defaultValue: []) as List;
    return historyJson
        .map((json) => Bookmark.fromJson(Map<String, dynamic>.from(json)))
        .toList();
  }

  Future<void> clearHistory() async {
    _box.delete('history');
  }

  Future<void> removeHistoryItem(int index) async {
    final history = await loadHistory();
    history.removeAt(index);
    await saveHistory(history);
  }
}
