import 'package:fuzzywuzzy/fuzzywuzzy.dart';
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
  final TantivyDataProvider _tantivyDataProvider = TantivyDataProvider.instance;

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
    return FileSystemData.getOtzarBooks();
  }

  /// Retrieves the list of books from the Hebrew Books project
  ///
  /// Returns a [Future] that completes with a list of [Book] objects
  /// representing books from the Hebrew Books collection
  Future<List<Book>> getHebrewBooks() {
    return FileSystemData.getHebrewBooks();
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

  /// Adds text content from the library to the Tantivy search index
  ///
  /// Parameters:
  ///   - [library]: The library containing books to index
  ///   - [start]: Starting index for batch processing (defaults to 0)
  ///   - [end]: Ending index for batch processing (defaults to 100000)
  addAllTextsToTantivy(
    Library library,
  ) async {
    _tantivyDataProvider.addAllTBooksToTantivy(library);
  }

  /// Searches for books based on query text and optional filters
  ///
  /// Parameters:
  ///   - [query]: The search text to match against book titles
  ///   - [category]: Optional category to filter results
  ///   - [topics]: Optional list of topics to filter results
  ///   - [includeOtzar]: Whether to include Otzar HaChochma books
  ///   - [includeHebrewBooks]: Whether to include HebrewBooks.org books
  ///
  /// Returns a [Future] that completes with a list of [Book] objects matching the criteria
  Future<List<Book>> findBooks(
    String query,
    Category? category, {
    List<String>? topics,
    bool includeOtzar = false,
    bool includeHebrewBooks = false,
  }) async {
    final queryWords = query.toLowerCase().split(RegExp(r'\s+'));
    var allBooks =
        category?.getAllBooks() ?? (await getLibrary()).getAllBooks();

    if (includeOtzar) {
      allBooks += await getOtzarBooks();
    }
    if (includeHebrewBooks) {
      allBooks += await getHebrewBooks();
    }

    // Filter books based on query and topics
    final filteredBooks = allBooks.where((book) {
      final title = book.title.toLowerCase();
      final bookTopics = book.topics.split(', ');

      bool matchesQuery = queryWords.every((word) => title.contains(word));
      bool matchesTopics = topics == null ||
          topics.isEmpty ||
          topics.every((t) => bookTopics.contains(t));

      return matchesQuery && matchesTopics;
    }).toList();

    //sort by levenstien distance

    filteredBooks
        .sort((a, b) => ratio(query, a.title).compareTo(ratio(query, b.title)));

    return filteredBooks;
  }
}
