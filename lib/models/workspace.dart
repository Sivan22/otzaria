import 'package:otzaria/models/bookmark.dart';

/// Represents a workspace in the application.
///
/// A `Workspace` object has a [name] which is the name of the workspace,
/// a [bookmarks] list which is a list of bookmarks in the workspace,
/// and a [currentTab] which is the index of the current tab.
class Workspace {
  String name;
  final List<Bookmark> bookmarks;
  int currentTab;

  Workspace({required this.name, required this.bookmarks, this.currentTab = 0});

  factory Workspace.fromJson(Map<String, dynamic> json) {
    return Workspace(
        name: json['name'],
        bookmarks: List<Bookmark>.from(
          json['bookmarks'].map((bookmark) => Bookmark.fromJson(bookmark)),
        ),
        currentTab: json['currentTab']);
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'bookmarks': bookmarks.map((bookmark) => bookmark.toJson()).toList(),
      'currentTab': currentTab
    };
  }
}
