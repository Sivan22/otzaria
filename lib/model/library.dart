/* a representation of the library , every entry could be a category or a book, and a category can
contain other categories and books */

import 'package:otzaria/model/books.dart';
import 'package:otzaria/data/file_system_data.dart';

class Category {
  String title;
  String get description =>
      FileSystemData.instance.metadata[title]?['heDesc'] ?? '';
  String get shortDescription =>
      FileSystemData.instance.metadata[title]?['heShortDesc'] ?? '';
  int get order => FileSystemData.instance.metadata[title]?['order'] ?? 999;
  List<Category> subCategories;
  Category? parent;
  List<Book> books;
  Category({
    required this.title,
    required this.subCategories,
    required this.books,
    required this.parent,
  });
}

class Library extends Category {
  Library({required List<Category> categories})
      : super(
            subCategories: categories,
            title: 'אוצריא',
            books: [],
            parent: null);
}
