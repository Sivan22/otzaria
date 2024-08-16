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

  Future<List<Ref>> findRefsByRelevance(String ref, {int limit = 10}) async {
    var refs = await findRefs(ref);
    // reduce the number of refs by taking the top N of each book
    refs = await Isolate.run(() {
      List<Ref> takenRefs = [];
      final gruops = refs.groupBy((ref) => ref.bookTitle);
      for (final gruop in gruops.keys) {
        takenRefs += (gruops[gruop]!.take(limit)).toList();
      }
      takenRefs.sort((a, b) {
        final scoreA = ratio(ref, a.ref);
        final scoreB = ratio(ref, b.ref);
        return scoreB.compareTo(scoreA);
      });
      return takenRefs;
    });

    // sort by ratio

    return refs;
  }
}

extension Iterables<E> on Iterable<E> {
  Map<K, List<E>> groupBy<K>(K Function(E) keyFunction) => fold(
      <K, List<E>>{},
      (Map<K, List<E>> map, E element) =>
          map..putIfAbsent(keyFunction(element), () => <E>[]).add(element));
}
