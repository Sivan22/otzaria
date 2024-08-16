import 'dart:math';
import 'package:flutter_mimir/flutter_mimir.dart';
import 'package:otzaria/models/books.dart';
import 'package:otzaria/models/library.dart';

addTextsToMimir(Library library, MimirIndex mimir,
    {int start = 0, int end = 100000}) async {
  var allBooks = library.getAllBooks().whereType<TextBook>().toList();
  allBooks = allBooks.getRange(start, min(end, allBooks.length)).toList();
  for (TextBook book in allBooks) {
    print('Adding ${book.title} to Mimir');
    await addTextToMimir(book, mimir);
  }
}

addTextToMimir(TextBook book, MimirIndex mimir) async {
  final text = await book.text;
  final title = book.title;
  final author = book.author;
  final topics = book.topics;

  final texts = text.split('\n');
  final List<Map<String, dynamic>> documents = [];
  for (int i = 0; i < texts.length; i++) {
    documents.add({
      'title': title,
      'author': author,
      'topics': topics,
      'text': texts[i],
      'index': i,
      'id': DateTime.now().millisecondsSinceEpoch + Random().nextInt(1000000),
    });
  }
  await mimir.addDocuments(documents);
  print('Added ${book.title} to Mimir');
}
