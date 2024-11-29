import 'package:otzaria/data/data_providers/file_system_data_provider.dart';
import 'package:otzaria/data/data_providers/isar_data_provider.dart';
import 'package:otzaria/data/data_providers/tantivy_data_provider.dart';
import 'package:otzaria/models/books.dart';
import 'package:otzaria/models/isar_collections/ref.dart';
import 'package:otzaria/models/library.dart';

/// DataRepository acts as a centralized data access layer that coordinates between different
/// data providers (file system, Isar database, and Tantivy search engine).
///
/// This repository implements the Repository pattern to abstract the data source
/// implementation details from the business logic. It provides a clean API for
/// accessing and manipulating application data from various sources.
class DataRepository {
  /// Handles file system operations like reading book texts and metadata
  final FileSystemData _fileSystemData = FileSystemData.instance;

  /// Manages database operations using Isar for storing and retrieving references
  final IsarDataProvider _isarDataProvider = IsarDataProvider.instance;

  /// Handles full-text search operations using Tantivy search engine
  final TantivyDataProvider _mimirDataProvider = TantivyDataProvider.instance;

  /// Singleton instance of the DataRepository
  static final DataRepository _singleton = DataRepository();

  /// Provides access to the singleton instance
  static DataRepository get instance => _singleton;

  /// Retrieves the complete library metadata including all available books
  ///
  /// Returns a [Future] that completes with a [Library] object containing
  /// the full library structure and metadata
  Future<Library> getLibrary() async {
    return _fileSystemData.getLibrary();
  }

  /// Retrieves the list of books from the Otzar HaHochma project
  ///
  /// Returns a [Future] that completes with a list of [ExternalBook] objects
  /// representing books from the Otzar HaHochma collection
  Future<List<ExternalBook>> getOtzarBooks() {
    return _fileSystemData.getOtzarBooks();
  }

  /// Retrieves the list of books from the Hebrew Books project
  ///
  /// Returns a [Future] that completes with a list of [ExternalBook] objects
  /// representing books from the Hebrew Books collection
  Future<List<ExternalBook>> getHebrewBooks() {
    return _fileSystemData.getHebrewBooks();
  }

  /// Retrieves the full text content of a specific book
  ///
  /// Parameters:
  ///   - [title]: The title of the book to retrieve
  ///
  /// Returns a [Future] that completes with the book's text content as a [String]
  Future<String> getBookText(String title) async {
    return _fileSystemData.getBookText(title);
  }

  /// Retrieves the table of contents for a specific book
  ///
  /// Parameters:
  ///   - [title]: The title of the book whose TOC should be retrieved
  ///
  /// Returns a [Future] that completes with a list of [TocEntry] objects
  /// representing the book's table of contents structure
  Future<List<TocEntry>> getBookToc(String title) async {
    return _fileSystemData.getBookToc(title);
  }

  /// Creates reference entries in the database from the library data
  ///
  /// Parameters:
  ///   - [library]: The library containing books to create references from
  ///   - [startIndex]: The index to start processing from, useful for batch processing
  Future<void> createRefsFromLibrary(Library library, int startIndex) async {
    _isarDataProvider.createRefsFromLibrary(library, startIndex);
  }

  /// Retrieves all references associated with a specific book
  ///
  /// Parameters:
  ///   - [book]: The book whose references should be retrieved
  ///
  /// Returns a list of [Ref] objects containing all references to/from the specified book
  List<Ref> getRefsForBook(TextBook book) {
    return _isarDataProvider.getRefsForBook(book);
  }

  /// Searches for references by relevance to a given reference string
  ///
  /// Parameters:
  ///   - [ref]: The reference string to search for
  ///   - [limit]: Maximum number of results to return (defaults to 10)
  ///
  /// Returns a [Future] that completes with a list of [Ref] objects sorted by relevance
  Future<List<Ref>> findRefsByRelevance(String ref, {int limit = 10}) {
    return _isarDataProvider.findRefsByRelevance(ref, limit: limit);
  }

  /// Gets the total count of books that have associated references
  ///
  /// Returns a [Future] that completes with the count of books with references
  Future<int> getNumberOfBooksWithRefs() {
    return _isarDataProvider.getNumberOfBooksWithRefs();
  }

  /// Adds text content from the library to the Tantivy search index
  ///
  /// Parameters:
  ///   - [library]: The library containing books to index
  ///   - [start]: Starting index for batch processing (defaults to 0)
  ///   - [end]: Ending index for batch processing (defaults to 100000)
  addAllTextsToTantivy(Library library,
      {int start = 0, int end = 100000}) async {
    _mimirDataProvider.addAllTBooksToTantivy(library, start: start, end: end);
  }
}
