import 'package:logging/logging.dart';
import 'package:otzaria/data/data_providers/file_system_data_provider.dart';
import 'package:otzaria/data/data_providers/isar_data_provider.dart';
import 'package:otzaria/data/data_providers/tantivy_data_provider.dart';
import 'package:otzaria/data/data_providers/sql_data_provider.dart';
import 'package:otzaria/data/data_providers/drift_database.dart' as drift;
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

  /// Manages database operations for external books
  final SqlDataProvider _sqlDataProvider = SqlDataProvider.instance;

  /// Handles full-text search operations using Tantivy search engine
  final TantivyDataProvider _mimirDataProvider = TantivyDataProvider.instance;

  /// Singleton instance of the DataRepository
  static final DataRepository _singleton = DataRepository._();

  /// Provides access to the singleton instance
  static DataRepository get instance => _singleton;

  final Logger _logger = Logger('DataRepository');

  bool _initialized = false;

  DataRepository._();

  /// Initializes all data providers and runs necessary migrations
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      _logger.info('Initializing data providers');
      // Initialize SQL provider (this will run CSV migration if needed)
      await _sqlDataProvider.initialize();
    } catch (e) {
      _logger.severe('Error initializing data providers', e);
      rethrow;
    }

    _initialized = true;
  }

  /// Retrieves the complete library metadata including all available books
  ///
  /// Returns a [Future] that completes with a [Library] object containing
  /// the full library structure and metadata
  Future<Library> getLibrary() async {
    try {
      _logger.info('Building library structure');
      await initialize(); // Ensure data providers are initialized
      
      final rootCategories = await _sqlDataProvider.database.getRootCategories();
      if (rootCategories.isEmpty) {
        _logger.info('No root categories found, returning empty library');
        return Library(
          title: 'אוצריא',
          subCategories: [],
          books: [],
        );
      }

      final rootCategory = rootCategories.first;
      _logger.info('Building library from root category: ${rootCategory.title}');
      
      final subCategories = await _buildCategoryTree(rootCategory.id);
      final books = await _buildBookList(
        await _sqlDataProvider.database.getBooksByCategory(rootCategory.id)
      );

      final library = Library(
        title: rootCategory.title,
        subCategories: subCategories,
        books: books,
      );

      // Set parent references
      _logger.info('Setting parent references for categories');
      for (var category in library.getAllCategories()) {
        category.parent = library;
      }

      _logger.info('Library structure built successfully');
      return library;
    } catch (e, stackTrace) {
      _logger.severe('Error building library', e, stackTrace);
      rethrow;
    }
  }

  Future<List<Category>> _buildCategoryTree(int categoryId) async {
    try {
      _logger.info('Building category tree for category $categoryId');
      final subcategories = await _sqlDataProvider.database.getSubcategories(categoryId);
      final List<Category> result = [];

      for (var dbCategory in subcategories) {
        final category = Category(
          title: dbCategory.title,
          description: dbCategory.description ?? '',
          shortDescription: dbCategory.shortDescription ?? '',
          order: dbCategory.order,
          books: await _buildBookList(await _sqlDataProvider.database.getBooksByCategory(dbCategory.id)),
          subCategories: await _buildCategoryTree(dbCategory.id),
          parent: null, // We'll set this after creation
        );
        result.add(category);
      }

      return result;
    } catch (e) {
      _logger.severe('Error building category tree', e);
      rethrow;
    }
  }

  Future<List<Book>> _buildBookList(List<drift.Book> dbBooks) async {
    try {
      _logger.info('Building book list');
      final List<Book> result = [];
      for (var dbBook in dbBooks) {
        final book = switch (dbBook.type) {
          'TextBook' => TextBook(
              title: dbBook.title,
              author: dbBook.author,
              heShortDesc: dbBook.heShortDesc,
              pubDate: dbBook.pubDate,
              pubPlace: dbBook.pubPlace,
              topics: dbBook.topics ?? '',
              order: dbBook.order,
            ),
          'PdfBook' => PdfBook(
              title: dbBook.title,
              path: dbBook.path!,
              author: dbBook.author,
              heShortDesc: dbBook.heShortDesc,
              pubDate: dbBook.pubDate,
              pubPlace: dbBook.pubPlace,
              topics: dbBook.topics ?? '',
              order: dbBook.order,
            ),
          'OtzarBook' => ExternalBook(
              title: dbBook.title,
              id: dbBook.metadata?['id'] as int? ?? 0,
              author: dbBook.author,
              heShortDesc: dbBook.heShortDesc,
              pubDate: dbBook.pubDate,
              pubPlace: dbBook.pubPlace,
              topics: dbBook.topics ?? '',
              link: dbBook.metadata?['link'] as String? ?? '',
            ),
          _ => throw Exception('Unknown book type: ${dbBook.type}'),
        };
        result.add(book);
      }
      return result;
    } catch (e) {
      _logger.severe('Error building book list', e);
      rethrow;
    }
  }

  /// Retrieves the list of books from the Otzar HaHochma project
  ///
  /// Returns a [Future] that completes with a list of [ExternalBook] objects
  /// representing books from the Otzar HaHochma collection
  Future<List<ExternalBook>> getOtzarBooks() async {
    try {
      _logger.info('Retrieving Otzar HaHochma books');
      final books = await _sqlDataProvider.getOtzarBooks();
      return books;
    } catch (e) {
      _logger.severe('Error retrieving Otzar HaHochma books', e);
      rethrow;
    }
  }

  /// Retrieves the list of books from the Hebrew Books project
  ///
  /// Returns a [Future] that completes with a list of [ExternalBook] objects
  /// representing books from the Hebrew Books collection
  Future<List<ExternalBook>> getHebrewBooks() async {
    try {
      _logger.info('Retrieving Hebrew Books');
      final books = await _sqlDataProvider.getHebrewBooks();
      return books;
    } catch (e) {
      _logger.severe('Error retrieving Hebrew Books', e);
      rethrow;
    }
  }

  /// Retrieves the full text content of a specific book
  ///
  /// Parameters:
  ///   - [title]: The title of the book to retrieve
  ///
  /// Returns a [Future] that completes with the book's text content as a [String]
  Future<String> getBookText(String title) async {
    try {
      _logger.info('Retrieving book text for $title');
      return _fileSystemData.getBookText(title);
    } catch (e) {
      _logger.severe('Error retrieving book text', e);
      rethrow;
    }
  }

  /// Retrieves the table of contents for a specific book
  ///
  /// Parameters:
  ///   - [title]: The title of the book whose TOC should be retrieved
  ///
  /// Returns a [Future] that completes with a list of [TocEntry] objects
  /// representing the book's table of contents structure
  Future<List<TocEntry>> getBookToc(String title) async {
    try {
      _logger.info('Retrieving book TOC for $title');
      return _fileSystemData.getBookToc(title);
    } catch (e) {
      _logger.severe('Error retrieving book TOC', e);
      rethrow;
    }
  }

  /// Creates reference entries in the database from the library data
  ///
  /// Parameters:
  ///   - [library]: The library containing books to create references from
  ///   - [startIndex]: The index to start processing from, useful for batch processing
  Future<void> createRefsFromLibrary(Library library, int startIndex) async {
    try {
      _logger.info('Creating references from library');
      _isarDataProvider.createRefsFromLibrary(library, startIndex);
    } catch (e) {
      _logger.severe('Error creating references', e);
      rethrow;
    }
  }

  /// Retrieves all references associated with a specific book
  ///
  /// Parameters:
  ///   - [book]: The book whose references should be retrieved
  ///
  /// Returns a list of [Ref] objects containing all references to/from the specified book
  List<Ref> getRefsForBook(TextBook book) {
    try {
      _logger.info('Retrieving references for book ${book.title}');
      return _isarDataProvider.getRefsForBook(book);
    } catch (e) {
      _logger.severe('Error retrieving references', e);
      rethrow;
    }
  }

  /// Searches for references by relevance to a given reference string
  ///
  /// Parameters:
  ///   - [ref]: The reference string to search for
  ///   - [limit]: Maximum number of results to return (defaults to 10)
  ///
  /// Returns a [Future] that completes with a list of [Ref] objects sorted by relevance
  Future<List<Ref>> findRefsByRelevance(String ref, {int limit = 10}) async {
    try {
      _logger.info('Searching for references by relevance');
      return _isarDataProvider.findRefsByRelevance(ref, limit: limit);
    } catch (e) {
      _logger.severe('Error searching for references', e);
      rethrow;
    }
  }

  /// Gets the total count of books that have associated references
  ///
  /// Returns a [Future] that completes with the count of books with references
  Future<int> getNumberOfBooksWithRefs() async {
    try {
      _logger.info('Retrieving number of books with references');
      return _isarDataProvider.getNumberOfBooksWithRefs();
    } catch (e) {
      _logger.severe('Error retrieving number of books with references', e);
      rethrow;
    }
  }

  /// Adds text content from the library to the Tantivy search index
  ///
  /// Parameters:
  ///   - [library]: The library containing books to index
  ///   - [start]: Starting index for batch processing (defaults to 0)
  ///   - [end]: Ending index for batch processing (defaults to 100000)
  Future<void> addAllTextsToTantivy(Library library,
      {int start = 0, int end = 100000}) async {
    try {
      _logger.info('Adding texts to Tantivy index');
      await _mimirDataProvider.addAllTBooksToTantivy(library, start: start, end: end);
    } catch (e) {
      _logger.severe('Error adding texts to Tantivy index', e);
      rethrow;
    }
  }
}
