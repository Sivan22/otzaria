import 'dart:isolate';

import 'package:isar/isar.dart';
import 'package:otzaria/models/books.dart';
import 'package:otzaria/models/isar_collections/ref.dart';
import 'package:fuzzywuzzy/fuzzywuzzy.dart';
import 'package:path_provider/path_provider.dart';

class IsarDataProvider {
  static final IsarDataProvider _singleton = IsarDataProvider();
  static IsarDataProvider get instance => _singleton;

  IsarDataProvider();

  final isar = Isar.open(
    directory: "C:\\Users\\Goldman\\AppData\\Roaming\\com.example\\otzaria",
    schemas: [RefSchema],
  );

  List<Ref> getRefsForBook(TextBook book) {
    return isar.refs.where().bookTitleEqualTo(book.title).findAll();
  }

  List<Ref> getAllRefs() {
    return isar.refs.where().findAll();
  }

  Future<List<Ref>> findRefs(String ref) {
    final parts = ref.split(' ');
    return isar.refs
        .where()
        .allOf(
          parts,
          (q, element) => q.refContains(element),
        )
        .findAllAsync();
  }

  Future<List<Ref>> findRefsByRelevance(String ref, {int limit = 50}) async {
    //final results = Isolate.run(() async {
    var refs = (await findRefs(ref)).take(limit).toList();
    // sort by ratio

    refs.sort((a, b) {
      final scoreA = ratio(ref, a.ref);
      final scoreB = ratio(ref, b.ref);
      return scoreB.compareTo(scoreA);
    });
    return refs;
    // });
    // return results;
  }
}
