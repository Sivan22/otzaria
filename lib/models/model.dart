import 'package:otzaria/data/data.dart';
import 'package:otzaria/data/file_system_data_provider.dart';
import 'package:otzaria/models/library.dart';
import 'package:otzaria/models/tabs.dart';

class AppModel {
  Data data = FileSystemData.instance;
  late Library library;
  List<OpenedTab> tabs = [];

  AppModel() {
    library = data.getLibrary();
  }

  void openTextBook(book) {}
}
