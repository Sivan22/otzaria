import 'package:otzaria/tabs/models/tab.dart';

/// Represents a workspace in the application.
///
/// A `Workspace` object has a [name] which is the name of the workspace,
/// a [bookmarks] list which is a list of bookmarks in the workspace,
/// and a [currentTab] which is the index of the current tab.
class Workspace {
  String name;
  final List<OpenedTab> tabs;
  int currentTab;

  Workspace({required this.name, required this.tabs, this.currentTab = 0});

  factory Workspace.fromJson(Map<String, dynamic> json) {
    return Workspace(
        name: json['name'],
        tabs: List<OpenedTab>.from(
          json['tabs'].map((tab) => OpenedTab.fromJson(tab)),
        ),
        currentTab: json['currentTab']);
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'tabs': tabs.map((tab) => tab.toJson()).toList(),
      'currentTab': currentTab
    };
  }
}
