import 'package:path_provider/path_provider.dart';
import 'package:hive/hive.dart';
import 'package:otzaria/models/bookmark.dart';

initHiveBoxes() async {
  Hive.registerAdapter<Bookmark>('Bookmark', (json) => Bookmark.fromJson(json));
  Hive.defaultDirectory = (await getApplicationSupportDirectory()).path;
  Hive.box(name: 'bookmarks');
  Hive.box(name: 'tabs');
}
