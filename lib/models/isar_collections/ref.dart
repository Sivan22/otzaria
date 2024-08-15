import 'package:isar/isar.dart';

part 'ref.g.dart';

@Collection()
class Ref {
  @Id()
  final int id;
  final String ref;
  final String bookTitle;
  final int index;
  Ref(
      {required this.id,
      required this.ref,
      required this.bookTitle,
      required this.index});
}
