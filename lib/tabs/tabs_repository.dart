import 'package:hive/hive.dart';
import 'package:otzaria/tabs/models/tab.dart';

class TabsRepository {
  static const String _tabsBoxKey = 'key-tabs';
  static const String _currentTabKey = 'key-current-tab';

  List<OpenedTab> loadTabs() {
    try {
      final box = Hive.box(name: 'tabs');
      final rawTabs = box.get(_tabsBoxKey, defaultValue: []) as List;
      return List<OpenedTab>.from(
        rawTabs.map((e) => OpenedTab.fromJson(e)).toList(),
      );
    } catch (e) {
      print('Error loading tabs from disk: $e');
      Hive.box(name: 'tabs').put(_tabsBoxKey, []);
      return [];
    }
  }

  int loadCurrentTabIndex() {
    return Hive.box(name: 'tabs').get(_currentTabKey, defaultValue: 0);
  }

  void saveTabs(List<OpenedTab> tabs, int currentTabIndex) {
    final box = Hive.box(name: 'tabs');
    box.put(_tabsBoxKey, tabs.map((tab) => tab.toJson()).toList());
    box.put(_currentTabKey, currentTabIndex);
  }
}
