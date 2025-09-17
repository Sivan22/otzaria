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

class BookmarkView extends StatefulWidget {
  const BookmarkView({Key? key}) : super(key: key);

  @override
  State<BookmarkView> createState() => _BookmarkViewState();
}

class _BookmarkViewState extends State<BookmarkView> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });

    // Auto-focus the search field when the screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _openBook(
      BuildContext context, Book book, int index, List<String>? commentators) {
    final tab = book is PdfBook
        ? PdfBookTab(
            book: book,
            pageNumber: index,
            openLeftPane: (Settings.getValue<bool>('key-pin-sidebar') ?? false) ||
                (Settings.getValue<bool>('key-default-sidebar-open') ?? false),
          )
        : TextBookTab(
            book: book as TextBook,
            index: index,
            commentators: commentators,
            openLeftPane: (Settings.getValue<bool>('key-pin-sidebar') ?? false) ||
                (Settings.getValue<bool>('key-default-sidebar-open') ?? false),
          );
          
    context.read<TabsBloc>().add(AddTab(tab));
    context.read<NavigationBloc>().add(const NavigateToScreen(Screen.reading));
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BookmarkBloc, BookmarkState>(
      builder: (context, state) {
        if (state.bookmarks.isEmpty) {
          return const Center(child: Text('אין סימניות'));
        }

        // Filter bookmarks based on search query
        final filteredBookmarks = _searchQuery.isEmpty
            ? state.bookmarks
            : state.bookmarks.where((bookmark) =>
                bookmark.ref.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                decoration: InputDecoration(
                  hintText: 'חפש בסימניות...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
                ),
              ),
            ),
            Expanded(
              child: filteredBookmarks.isEmpty
                  ? const Center(child: Text('לא נמצאו תוצאות'))
                  : ListView.builder(
                itemCount: filteredBookmarks.length,
                itemBuilder: (context, index) {
                  final bookmark = filteredBookmarks[index];
                  final originalIndex = state.bookmarks.indexOf(bookmark);
                  return ListTile(
                    selected: false,
                    leading: bookmark.book is PdfBook
                        ? const Icon(Icons.picture_as_pdf)
                        : null,
                    title: Text(bookmark.ref),
                    onTap: () => _openBook(
                        context,
                        bookmark.book,
                        bookmark.index,
                        bookmark.commentatorsToShow),
                    trailing: IconButton(
                      icon: const Icon(
                        Icons.delete_forever,
                      ),
                      onPressed: () {
                        context
                            .read<BookmarkBloc>()
                            .removeBookmark(originalIndex);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('הסימניה נמחקה'),
                          ),
                        );
                      },
                    ),
                  );
                },
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
                      duration: const Duration(milliseconds: 350),
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
