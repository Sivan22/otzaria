import 'package:otzaria/models/bookmark.dart';

class Workspace {
  String name;
  final List<Bookmark> bookmarks;
  int currentTab;

  Workspace({required this.name, required this.bookmarks, this.currentTab = 0});

  factory Workspace.fromJson(Map<String, dynamic> json) {
    return Workspace(
      name: json['name'],
      bookmarks: List<Bookmark>.from(
          json['bookmarks'].map((bookmark) => Bookmark.fromJson(bookmark))),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'bookmarks': bookmarks.map((bookmark) => bookmark.toJson()).toList(),
    };
  }
}
