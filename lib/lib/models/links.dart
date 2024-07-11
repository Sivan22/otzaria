/* represents links between two books in the library*/

import 'package:otzaria/data/file_system_data_provider.dart';
import 'package:otzaria/models/books.dart';
import 'dart:isolate';
import 'package:otzaria/data/data.dart';
import 'package:otzaria/utils/text_manipulation.dart' as utils;

/// Represents a link between two books in the library.
class Link {
  /// The [Data] object used for file system operations.
  final Data data = FileSystemData.instance;

  /// The Hebrew reference of the link.
  final String heRef;

  /// The index of the first book in the link.
  final int index1;

  /// The path of the second book in the link.
  final String path2;

  /// The index of the second book in the link.
  final int index2;

  /// The type of the connection in the link.
  final String connectionType;

  /// Creates a new instance of [Link] with the provided parameters.
  Link({
    required this.heRef,
    required this.index1,
    required this.path2,
    required this.index2,
    required this.connectionType,
  });

  /// Returns the content of the link as a [Future] of [String].
  Future<String> get content => data.getLinkContent(this);

  /// Constructs a [Link] object from a JSON object.
  ///
  /// The JSON object should have the following keys:
  /// - 'heRef_2': The Hebrew reference of the link.
  /// - 'line_index_1': The index of the first book in the link.
  /// - 'path_2': The path of the second book in the link.
  /// - 'line_index_2': The index of the second book in the link.
  /// - 'Conection Type': The type of the connection in the link.
  Link.fromJson(Map<String, dynamic> json)
      : heRef = json['heRef_2'].toString(),
        index1 = int.parse(json['line_index_1'].toString().split('.').first),
        path2 = json['path_2'].toString(),
        index2 = int.parse(json['line_index_2'].toString().split('.').first),
        connectionType = json['Conection Type'].toString();
}

/// Retrieves a list of [Link] objects for the given list of [indexes] and the [links] to be processed.
///
/// The [indexes] parameter is a required list of integers representing the indexes of the links to retrieve.
/// The [links] parameter is a required [Future] of a list of [Link] objects representing the links to be processed.
/// The [commentatorsToShow] parameter is a required list of [Book] objects representing the commentators to show.
///
/// Returns a [Future] of a list of [Link] objects representing the retrieved links.
///
/// The function retrieves the list of links by first awaiting the completion of the [links] future.
/// It then iterates over each index in the [indexes] list and filters the retrieved links based on the following criteria:
/// - The index of the link should be equal to the current index plus one.
/// - The connection type of the link should be either "commentary" or "targum".
/// - The title of the second book in the link should be present in the list of commentators to show.
/// The filtered links are added to the [allLinks] list.
/// After iterating over all the indexes, the [allLinks] list is sorted based on the order of the commentators to show.
/// The sorted list of links is then returned as a [Future] of a list of [Link] objects.
Future<List<Link>> getLinksforIndexs(
    {required List<int> indexes,
    required Future<List<Link>> links,
    required List<String> commentatorsToShow}) async {
  List<Link> doneLinks = await links;
  List<Link> allLinks = [];
  allLinks = await Isolate.run(() {
    for (int i = 0; i < indexes.length; i++) {
      List<Link> thisLinks = doneLinks
          .where((link) =>
              link.index1 == indexes[i] + 1 &&
              (link.connectionType == "commentary" ||
                  link.connectionType == "targum") &&
              commentatorsToShow.contains(utils.getTitleFromPath(link.path2)))
          .toList();
      allLinks += thisLinks;
    }

    allLinks.sort(
        //sort by the order of the commentators to show and then by the heRef
        (a, b) {
      return a.heRef.compareTo(b.heRef);
    });

    allLinks.sort(
        //sort by the order of the commentators to show and then by the heRef
        (a, b) {
      return commentatorsToShow
          .indexOf(utils.getTitleFromPath(a.path2))
          .compareTo(
              commentatorsToShow.indexOf(utils.getTitleFromPath(b.path2)));
    });
    return allLinks;
  });
  return allLinks;
}
