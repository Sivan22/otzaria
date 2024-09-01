import 'package:isar/isar.dart';

part 'ref.g.dart';

@Collection()
class Ref {
  @Id()
  final int id;
  final String ref;
  final String bookTitle;
  final int index;
  final bool pdfBook;
  final String? pdfPath;
  Ref(
      {required this.id,
      required this.ref,
      required this.bookTitle,
      required this.index,
      required this.pdfBook,
      this.pdfPath});
}
