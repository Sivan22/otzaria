import 'package:otzaria/data/data.dart';
import 'package:otzaria/data/file_system_data.dart';
import 'package:otzaria/model/library.dart';
import 'package:otzaria/model/tabs.dart';

class AppModel {
  Data data = FileSystemData.instance;
  late Library library;
  List<OpenedTab> tabs = [];

  AppModel() {
    library = data.getLibrary();
  }

  void openTextBook(book) {}
}
