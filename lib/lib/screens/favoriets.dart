/// a widget that contains two tabs: history and bookmarks.
///  The bookmarks tab is BookmarkView and the history is HistoryView.
import 'package:flutter/material.dart';
import 'package:otzaria/screens/history_screen.dart';
import 'package:otzaria/screens/bookmark_screen.dart';

class FavouritesScreen extends StatelessWidget {
  const FavouritesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const DefaultTabController(
      length: 2,
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
            HistoryView(),
          ],
        ),
      ),
    );
  }
}
