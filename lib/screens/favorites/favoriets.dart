/// a widget that contains two tabs: history and bookmarks.
///  The bookmarks tab is BookmarkView and the history is HistoryView.
import 'package:flutter/material.dart';
import 'package:otzaria/screens/favorites/history_screen.dart';
import 'package:otzaria/screens/favorites/bookmark_screen.dart';
import 'package:otzaria/screens/favorites/workspaces_screen.dart';

class FavouritesScreen extends StatelessWidget {
  const FavouritesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: TabBar(
          tabs: [
            Tab(
              text: 'סימניות',
              icon: Icon(
                Icons.bookmark,
              ),
            ),
            Tab(
              text: 'סביבות עבודה',
              icon: Icon(
                Icons.workspaces_outline,
              ),
            ),
            Tab(
              text: 'היסטוריה',
              icon: Icon(
                Icons.history,
              ),
            ),
          ],
        ),
        body: TabBarView(
          children: [
            BookmarkView(),
            WorkspacesView(),
            HistoryView(),
          ],
        ),
      ),
    );
  }
}
