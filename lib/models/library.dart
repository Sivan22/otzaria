/* a representation of the library , every entry could be a category or a book, and a category can
contain other categories and books */

import 'package:otzaria/models/books.dart';
import 'package:otzaria/data/file_system_data_provider.dart';

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
  String get description =>
      FileSystemData.instance.metadata[title]?['heDesc'] ?? '';

  /// A short description of the category, obtained from [Data.metadata].
  String get shortDescription =>
      FileSystemData.instance.metadata[title]?['heShortDesc'] ?? '';

  /// The order of the category, obtained from [Data.metadata].
  /// Defaults to 999 if no order is specified for this category.
  int get order => FileSystemData.instance.metadata[title]?['order'] ?? 999;

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
            subCategories: categories,
            books: [],
            parent: null) {
    parent = this;
  }
}
