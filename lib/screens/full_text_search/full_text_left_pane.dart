import 'package:flutter/material.dart';
import 'package:otzaria/models/app_model.dart';
import 'package:otzaria/models/books.dart';
import 'package:otzaria/models/tabs.dart';
import 'package:otzaria/screens/full_text_search/full_text_book_list.dart';
import 'package:otzaria/screens/full_text_search/full_text_book_tree.dart';
import 'package:otzaria/screens/full_text_search/full_text_settings_screen.dart';
import 'package:provider/provider.dart';

class FullTextLeftPane extends StatefulWidget {
  final SearchingTab tab;
  const FullTextLeftPane({Key? key, required this.tab}) : super(key: key);
  @override
  _FullTextLeftPaneState createState() => _FullTextLeftPaneState();
}

class _FullTextLeftPaneState extends State<FullTextLeftPane>
    with SingleTickerProviderStateMixin {
  late TabController tabController;
  @override
  void initState() {
    tabController = TabController(length: 3, vsync: this);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      TabBar(
        controller: tabController,
        tabs: const [
          Tab(
            text: "הגדרות",
          ),
          Tab(
            text: " סינון",
          ),
          Tab(
            text: " עץ ספרים",
          ),
        ],
      ),
      Expanded(
        child: TabBarView(
          controller: tabController,
          children: [
            FullTextSettingsScreen(tab: widget.tab),
            FutureBuilder(
                future: getBooks(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  return FullTextBookList(
                    tab: widget.tab,
                    books: snapshot.data!,
                  );
                }),
            FullTextBookTree(tab: widget.tab),
          ],
        ),
      ),
    ]);
  }

  Future<List<Book>> getBooks() async {
    final books = (await Provider.of<AppModel>(context, listen: false).library)
        .getAllBooks();
    books.sort(
      (a, b) => a.title.trim().compareTo(b.title.trim()),
    );
    return books;
  }
}
