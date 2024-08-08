import 'package:otzaria/models/books.dart';

List<String> getAllTopics(List<Book> books) {
  List<String> topics = [];
  for (var book in books) {
    for (var topic in book.topics.split(', ')) {
      if (!topics.contains(topic)) {
        topics.add(topic);
      }
    }
  }
  topics.sort((a, b) => a.compareTo(b));
  return topics;
}
