import 'package:otzaria/data/data_providers/file_system_data_provider.dart';
import 'package:otzaria/models/books.dart';
import 'package:otzaria/models/links.dart';
import 'package:otzaria/utils/text_manipulation.dart';

class TextBookRepository {
  final FileSystemData _fileSystem;

  TextBookRepository({
    required FileSystemData fileSystem,
  }) : _fileSystem = fileSystem;

  Future<String> getBookContent(TextBook book) async {
    return await book.text;
  }

  /// Gets partial book content around a specific index (more efficient for large books)
  Future<List<String>> getPartialBookContent(TextBook book, int currentIndex, {int sectionsAround = 50}) async {
    return await book.getPartialText(currentIndex, sectionsAround: sectionsAround);
  }

  Future<List<Link>> getBookLinks(TextBook book) async {
    return await book.links;
  }

  Future<List<TocEntry>> getTableOfContents(TextBook book) async {
    return await book.tableOfContents;
  }

  Future<List<String>> getAvailableCommentators(List<Link> links) async {
    List<Link> filteredLinks = links
        .where((link) =>
            link.connectionType == 'commentary' ||
            link.connectionType == 'targum')
        .toList();

    List<String> paths = filteredLinks.map((e) => e.path2).toList();
    List<String> uniquePaths = paths.toSet().toList();
    List<String> commentatorTitles = uniquePaths
        .map(
          (e) => getTitleFromPath(e),
        )
        .toList();

    // Filter commentators asynchronously
    List<String> availableCommentators = [];
    for (String title in commentatorTitles) {
      if (await _fileSystem.bookExists(title)) {
        availableCommentators.add(title);
      }
    }

    availableCommentators.sort(
      (a, b) => a.compareTo(b),
    );
    return availableCommentators;
  }

  Future<bool> bookExists(String title) async {
    return await _fileSystem.bookExists(title);
  }
}
