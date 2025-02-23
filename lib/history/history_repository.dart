import 'package:hive/hive.dart';
import 'package:otzaria/bookmarks/models/bookmark.dart';
import 'package:otzaria/pdf_book/bloc/pdf_book_state.dart';
import 'package:otzaria/tabs/models/pdf_tab.dart';
import 'package:otzaria/tabs/models/tab.dart';
import 'package:otzaria/tabs/models/text_tab.dart';
import 'package:otzaria/utils/ref_helper.dart';

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

  Future<void> addHistoryItem(Bookmark bookmark) async {
    final history = await loadHistory();
    history.insert(0, bookmark);
    await saveHistory(history);
  }

  Future<void> addHistoryFromTab(OpenedTab tab) async {
    if (tab is PdfBookTab && tab.bloc.state is PdfBookLoaded) {
      final state = tab.bloc.state as PdfBookLoaded;
      int index = state.controller.pageNumber ?? 1;
      addHistoryItem(Bookmark(
        ref: '${tab.title} עמוד $index',
        book: tab.book,
        index: index,
      ));
    }
    if (tab is TextBookTab) {
      final index =
          tab.bloc.state.positionsListener.itemPositions.value.first.index;
      addHistoryItem(Bookmark(
        ref: await refFromIndex(index, tab.book.tableOfContents),
        book: tab.book,
        index: index,
      ));
    }
  }

  Future<void> removeHistoryItem(int index) async {
    final history = await loadHistory();
    history.removeAt(index);
    await saveHistory(history);
  }
}
