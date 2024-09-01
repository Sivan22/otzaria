import 'package:isar/isar.dart';

part 'line.g.dart';

@Collection()
class Line {
  final int id;
  final String text;
  final String bookTitle;
  final String topics;
  final int index;

  Line(
      {required this.id,
      required this.text,
      required this.bookTitle,
      required this.topics,
      required this.index});
}
