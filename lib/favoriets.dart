/// a widget that contains two tabs: history and bookmarks.
///  The bookmarks tab is BookmarkView and the history is HistoryView.
import 'package:flutter/material.dart';
import 'package:otzaria/history/history_screen.dart';
import 'package:otzaria/bookmarks/bookmark_screen.dart';
import 'package:otzaria/workspaces/workspaces_screen.dart';

class FavouritesScreen extends StatefulWidget {
  const FavouritesScreen({Key? key}) : super(key: key);

  @override
  State<FavouritesScreen> createState() => _FavouritesScreenState();
}

class _FavouritesScreenState extends State<FavouritesScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
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
