import 'package:isar/isar.dart';
import 'package:otzaria/models/books.dart';
import 'package:otzaria/models/isar_collections/ref.dart';
import 'package:fuzzywuzzy/fuzzywuzzy.dart';

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

  List<Ref> getAllRefs() {
    return isar.refs.where().findAll();
  }

  List<Ref> findRefs(String ref) {
    final parts = ref.split(' ');
    return isar.refs
        .where()
        .allOf(
          parts,
          (q, element) => q.refContains(element),
        )
        .findAll();
  }

  List<Ref> findRefsByRelevance(String ref, {int limit = 50}) {
    var refs = findRefs(ref).take(limit).toList();
    // sort by ratio

    refs.sort((a, b) {
      final scoreA = ratio(ref, a.ref);
      final scoreB = ratio(ref, b.ref);
      return scoreB.compareTo(scoreA);
    });
    return refs;
  }
}
