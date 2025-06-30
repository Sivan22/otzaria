import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:otzaria/bookmarks/bloc/bookmark_bloc.dart';
import 'package:otzaria/bookmarks/bloc/bookmark_state.dart';
import 'package:otzaria/navigation/bloc/navigation_bloc.dart';
import 'package:otzaria/navigation/bloc/navigation_event.dart';
import 'package:otzaria/navigation/bloc/navigation_state.dart';
import 'package:otzaria/tabs/bloc/tabs_bloc.dart';
import 'package:otzaria/tabs/bloc/tabs_event.dart';
import 'package:otzaria/tabs/models/pdf_tab.dart';
import 'package:otzaria/tabs/models/text_tab.dart';
import 'package:otzaria/models/books.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';

class BookmarkView extends StatelessWidget {
  const BookmarkView({Key? key}) : super(key: key);

  void _openBook(
      BuildContext context, Book book, int index, List<String>? commentators) {
    final tab = book is PdfBook
        ? PdfBookTab(
            book: book,
            pageNumber: index,
            openLeftPane:
                Settings.getValue<bool>('key-default-sidebar-open') ?? false,
          )
        : TextBookTab(
            book: book as TextBook,
            index: index,
            commentators: commentators,
            openLeftPane:
                Settings.getValue<bool>('key-default-sidebar-open') ?? false,
          );
          
    context.read<TabsBloc>().add(AddTab(tab));
    context.read<NavigationBloc>().add(const NavigateToScreen(Screen.reading));
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BookmarkBloc, BookmarkState>(
      builder: (context, state) {
        return state.bookmarks.isEmpty
            ? const Center(child: Text('אין סימניות'))
            : Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      itemCount: state.bookmarks.length,
                      itemBuilder: (context, index) => ListTile(
                          selected: false,
                          title: Text(state.bookmarks[index].ref),
                          onTap: () => _openBook(
                              context,
                              state.bookmarks[index].book,
                              state.bookmarks[index].index,
                              state.bookmarks[index].commentatorsToShow),
                          trailing: IconButton(
                            icon: const Icon(
                              Icons.delete_forever,
                            ),
                            onPressed: () {
                              context
                                  .read<BookmarkBloc>()
                                  .removeBookmark(index);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('הסימניה נמחקה'),
                                ),
                              );
                            },
                          )),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ElevatedButton(
                      onPressed: () {
                        context.read<BookmarkBloc>().clearBookmarks();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('כל הסימניות נמחקו'),
                          ),
                        );
                      },
                      child: const Text('מחק את כל הסימניות'),
                    ),
                  ),
                ],
              );
      },
    );
  }
}
