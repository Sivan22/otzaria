import 'package:isar/isar.dart';
import 'package:otzaria/models/books.dart';
import 'package:otzaria/models/isar_collections/ref.dart';

class IsarDataProvider {
  IsarDataProvider._();
  static final IsarDataProvider _singleton = IsarDataProvider._();
  static IsarDataProvider get instance => _singleton;

  final isar = Isar.open(
    directory: '.',
    schemas: [RefSchema],
  );

  List<Ref> getRefsForBook(TextBook book) {
    return isar.refs.where().bookTitleEqualTo(book.title).findAll();
  }
}
