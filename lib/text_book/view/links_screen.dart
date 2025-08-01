// a widget that takes an html strings array, finds all the headings, and displays it in a listview. on pressed the scrollcontroller scrolls to the index of the heading.

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:otzaria/models/books.dart';
import 'package:otzaria/tabs/models/text_tab.dart';
import 'package:otzaria/text_book/bloc/text_book_bloc.dart';
import 'package:otzaria/text_book/bloc/text_book_state.dart';
import 'package:otzaria/utils/text_manipulation.dart' as utils;
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'dart:io';
import 'package:otzaria/tabs/models/tab.dart';
import 'package:otzaria/models/links.dart';

class LinksViewer extends StatefulWidget {
  final Function(OpenedTab tab) openTabcallback;
  final ItemPositionsListener itemPositionsListener;
  final void Function() closeLeftPanelCallback;

  const LinksViewer({
    super.key,
    required this.openTabcallback,
    required this.itemPositionsListener,
    required this.closeLeftPanelCallback,
  });

  /// Returns the visible links for the provided [state].
  ///
  /// This method filters out commentary links and sorts the result by
  /// the book name so that callers such as context menus can easily
  /// display them synchronously.
  static List<Link> getLinks(TextBookLoaded state) {
    final links = state.links
        .where(
          (link) =>
              link.index1 == state.visibleIndices.first + 2 &&
              link.connectionType != 'commentary',
        )
        .toList();

    links.sort(
      (a, b) => a.path2
          .split(Platform.pathSeparator)
          .last
          .compareTo(b.path2.split(Platform.pathSeparator).last),
    );

    return links;
  }

  @override
  State<LinksViewer> createState() => _LinksViewerState();
}

class _LinksViewerState extends State<LinksViewer>
    with AutomaticKeepAliveClientMixin<LinksViewer> {
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return BlocBuilder<TextBookBloc, TextBookState>(
      builder: (context, state) {
        if (state is TextBookError) {
          return Center(child: Text('Error: ${state.message}'));
        }
        if (state is! TextBookLoaded) {
          return const Center(child: CircularProgressIndicator());
        }
        return FutureBuilder(
          future: Future<List<Link>>.value(LinksViewer.getLinks(state)),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return ListView.builder(
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) => ListTile(
                  title: Text(snapshot.data![index].heRef),
                  onTap: () {
                    widget.openTabcallback(
                      TextBookTab(
                        book: TextBook(
                          title: utils.getTitleFromPath(
                            snapshot.data![index].path2,
                          ),
                        ),
                        index: snapshot.data![index].index2 - 1,
                        openLeftPane:
                            (Settings.getValue<bool>('key-pin-sidebar') ?? false) ||
                                (Settings.getValue<bool>('key-default-sidebar-open') ??
                                    false),
                      ),
                    );
                    if (MediaQuery.of(context).size.width < 600) {
                      widget.closeLeftPanelCallback();
                    }
                  },
                ),
              );
            }
            return const Center(child: CircularProgressIndicator());
          },
        );
      },
    );
  }

  @override
  get wantKeepAlive => false;
}
