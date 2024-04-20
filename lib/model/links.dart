import 'package:otzaria/data/file_system_data.dart';
import 'package:otzaria/model/books.dart';
import 'dart:isolate';
import 'package:otzaria/data/data.dart';
import 'package:otzaria/utils/text_manipulation.dart' as utils;

class Link {
  final Data data = FileSystemData.instance;
  final String heRef;
  final int index1;
  final String path2;
  final int index2;
  final String connectionType;

  Link({
    required this.heRef,
    required this.index1,
    required this.path2,
    required this.index2,
    required this.connectionType,
  });

  Future<String> get content => data.getLinkContent(this);

// send this Link object to the isolate

// another constructor for the Link class that takes a json object as a parameter
  Link.fromJson(Map<String, dynamic> json)
      : heRef = json['heRef_2'].toString(),
        index1 = int.parse(json['line_index_1'].toString().split('.').first),
        path2 = json['path_2'].toString(),
        index2 = int.parse(json['line_index_2'].toString().split('.').first),
        connectionType = json['Conection Type'].toString();
}

Future<List<Link>> getLinksforIndexs(
    {required List<int> indexes,
    required Future<List<Link>> links,
    required List<Book> commentatorsToShow}) async {
  List<Link> doneLinks = await links;
  List<Link> allLinks = [];
  final titles = commentatorsToShow.map((e) => e.title).toList();
  allLinks = await Isolate.run(() {
    for (int i = 0; i < indexes.length; i++) {
      List<Link> thisLinks = doneLinks
          .where((link) =>
              link.index1 == indexes[i] + 1 &&
              (link.connectionType == "commentary" ||
                  link.connectionType == "targum") &&
              titles.contains(utils.getTitleFromPath(link.path2)))
          .toList();
      allLinks += thisLinks;
    }
    //sort by the order of the commentatorstoshow
    allLinks.sort((a, b) => titles
        .indexOf(utils.getTitleFromPath(a.path2))
        .compareTo(titles.indexOf(utils.getTitleFromPath(a.path2))));
    return allLinks;
  });
  return allLinks;
}
