/* a representation of the library , every entry could be a category or a book, and a category can
contain other categories and books */

import 'package:otzaria/models/books.dart';
import 'package:otzaria/data/data_providers/file_system_data_provider.dart';

/// Represents a category in the library.
///
/// A category in the library can contain other categories and books.
/// It has a [title], [subCategories], [books], and a [parent] category.
/// The [title] is a string representing the name of the category.
/// The [subCategories] is a list of categories that are contained in this category.
/// The [books] is a list of books that are contained in this category.
/// The [parent] is a pointer to the parent category. the top level category's parent is the library itself
///
/// The [description], [shortDescription], and [order] properties retrieve additional
/// information about the category from [Data.metadata].
class Category {
  String title;

  /// A description of the category, obtained from [Data.metadata].
  String description;

  /// A short description of the category, obtained from [Data.metadata].
  String shortDescription;

  /// The order of the category, obtained from [Data.metadata].
  /// Defaults to 999 if no order is specified for this category.
  int order;

  ///the list of sub categories that are contained in this category
  List<Category> subCategories;

  /// the list of books that are contained in this category
  List<Book> books;

  /// A pointer to the parent category, or null if this is a top level category.
  Category? parent;

  ///returns all the books in this category and its subcategories
  List<Book> getAllBooks() {
    List<Book> books = [];
    books.addAll(this.books);
    for (Category category in subCategories) {
      books.addAll(category.getAllBooks());
    }
    return books;
  }

  List<Category> getAllCategories() {
    List<Category> categories = [];
    categories.addAll(subCategories);
    for (Category category in subCategories) {
      categories.addAll(category.getAllCategories());
    }
    return categories;
  }

  List<dynamic> getAllBooksAndCategories() {
    List<dynamic> booksAndCategories = [];
    booksAndCategories.addAll(getAllBooks());
    booksAndCategories.addAll(getAllCategories());
    return booksAndCategories;
  }

  /// Initialize a new [Category] instance.
  ///
  /// The [title] is the name of the category, [subCategories] are the categories
  /// that are contained in this category, [books] are the books that are contained
  /// in this category, and [parent] is the parent category.
  Category({
    required this.title,
    required this.description,
    required this.shortDescription,
    required this.order,
    required this.subCategories,
    required this.books,
    required this.parent,
  });
}

/// Represents a library of categories and books.
///
/// A library is a top level category that contains other categories.
/// It has a [title], a list of [subCategories], and a list of [books].
/// The [parent] of a library is the library itself.
class Library extends Category {
  /// Initialize a new [Library] instance.
  ///
  /// The [categories] parameter is a list of categories that are contained in
  /// this library.
  Library({required List<Category> categories})
      : super(
            title: 'ספריית אוצריא',
            description: '',
            shortDescription: '',
            order: 0,
            subCategories: categories,
            books: [],
            parent: null) {
    parent = this;
  }

  /// Finds a book by its title in the library.
  ///
  /// Searches through all books in the library and its subcategories
  /// for a book with the specified title.
  ///
  /// Returns the first matching [Book] or null if no book is found.
  Book? findBookByTitle(String title, Type? type) {
    List<Book> allBooks = getAllBooks();
    try {
      if (type == null) {
        return allBooks.firstWhere((book) => book.title == title);
      }
      return allBooks.firstWhere(
          (book) => book.title == title && book.runtimeType == type);
    } catch (e) {
      return null;
    }
  }
}
