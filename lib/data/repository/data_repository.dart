import 'package:otzaria/data/data_providers/file_system_data_provider.dart';
import 'package:otzaria/data/data_providers/isar_data_provider.dart';
import 'package:otzaria/data/data_providers/tantivy_data_provider.dart';
import 'package:otzaria/models/books.dart';
import 'package:otzaria/models/isar_collections/ref.dart';
import 'package:otzaria/models/library.dart';

class DataRepository {
  final FileSystemData _fileSystemData = FileSystemData.instance;
  final IsarDataProvider _isarDataProvider = IsarDataProvider.instance;
  final TantivyDataProvider _mimirDataProvider = TantivyDataProvider.instance;

  static final DataRepository _singleton = DataRepository();
  static DataRepository get instance => _singleton;

  Future<Library> getLibrary() async {
    return _fileSystemData.getLibrary();
  }

  ///returns the list of otzar books
  Future<List<ExternalBook>> getOtzarBooks() {
    return _fileSystemData.getOtzarBooks();
  }

  Future<List<ExternalBook>> getHebrewBooks() {
    return _fileSystemData.getHebrewBooks();
  }

  Future<String> getBookText(String title) async {
    return _fileSystemData.getBookText(title);
  }

  Future<List<TocEntry>> getBookToc(String title) async {
    return _fileSystemData.getBookToc(title);
  }

  Future<void> createRefsFromLibrary(Library library, int startIndex) async {
    _isarDataProvider.createRefsFromLibrary(library, startIndex);
  }

  List<Ref> getRefsForBook(TextBook book) {
    return _isarDataProvider.getRefsForBook(book);
  }

  Future<List<Ref>> findRefsByRelevance(String ref, {int limit = 10}) {
    return _isarDataProvider.findRefsByRelevance(ref, limit: limit);
  }

  addAllTextsToMimir(Library library, {int start = 0, int end = 100000}) async {
    _mimirDataProvider.addAllTBooksToTantivy(library, start: start, end: end);
  }
}
