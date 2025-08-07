import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:otzaria/history/bloc/history_bloc.dart';
import 'package:otzaria/history/bloc/history_event.dart';
import 'package:otzaria/history/bloc/history_state.dart';
import 'package:otzaria/models/books.dart';
import 'package:otzaria/navigation/bloc/navigation_bloc.dart';
import 'package:otzaria/navigation/bloc/navigation_event.dart';
import 'package:otzaria/navigation/bloc/navigation_state.dart';
import 'package:otzaria/tabs/bloc/tabs_bloc.dart';
import 'package:otzaria/search/bloc/search_bloc.dart';
import 'package:otzaria/search/bloc/search_event.dart';
import 'package:otzaria/tabs/bloc/tabs_event.dart';
import 'package:otzaria/tabs/models/pdf_tab.dart';
import 'package:otzaria/tabs/models/searching_tab.dart';
import 'package:otzaria/tabs/models/text_tab.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';

class HistoryView extends StatelessWidget {
  const HistoryView({Key? key}) : super(key: key);
  void _openBook(
      BuildContext context, Book book, int index, List<String>? commentators) {
    final tab = book is PdfBook
        ? PdfBookTab(
            book: book,
            pageNumber: index,
            openLeftPane: (Settings.getValue<bool>('key-pin-sidebar') ??
                    false) ||
                (Settings.getValue<bool>('key-default-sidebar-open') ?? false),
          )
        : TextBookTab(
            book: book as TextBook,
            index: index,
            commentators: commentators,
            openLeftPane: (Settings.getValue<bool>('key-pin-sidebar') ??
                    false) ||
                (Settings.getValue<bool>('key-default-sidebar-open') ?? false),
          );

    context.read<TabsBloc>().add(AddTab(tab));
    context.read<NavigationBloc>().add(const NavigateToScreen(Screen.reading));
    // Close the dialog if this view is displayed inside one
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  Widget? _getLeadingIcon(Book book, bool isSearch) {
    if (isSearch) {
      return const Icon(Icons.search);
    }
    if (book is PdfBook) {
      if (book.path.toLowerCase().endsWith('.docx')) {
        return const Icon(Icons.description);
      }
      return const Icon(Icons.picture_as_pdf);
    }
    if (book is TextBook) {
      return const Icon(Icons.article);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HistoryBloc, HistoryState>(
      builder: (context, state) {
        if (state is HistoryLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is HistoryError) {
          return Center(child: Text('Error: ${state.message}'));
        }

        if (state.history.isEmpty) {
          return const Center(child: Text('אין היסטוריה'));
        }

        return Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: state.history.length,
                itemBuilder: (context, index) {
                  final historyItem = state.history[index];
                  return ListTile(
                    leading:
                        _getLeadingIcon(historyItem.book, historyItem.isSearch),
                    title: Text(historyItem.ref),
                    onTap: () {
                      if (historyItem.isSearch) {
                        final tabsBloc = context.read<TabsBloc>();
                        // Always create a new search tab instead of reusing existing one
                        final searchTab = SearchingTab('חיפוש', null);
                        tabsBloc.add(AddTab(searchTab));

                        // Restore search query and options
                        searchTab.queryController.text = historyItem.book.title;
                        searchTab.searchOptions.clear();
                        searchTab.searchOptions
                            .addAll(historyItem.searchOptions ?? {});
                        searchTab.alternativeWords.clear();
                        searchTab.alternativeWords
                            .addAll(historyItem.alternativeWords ?? {});
                        searchTab.spacingValues.clear();
                        searchTab.spacingValues
                            .addAll(historyItem.spacingValues ?? {});

                        // Trigger search
                        searchTab.searchBloc.add(UpdateSearchQuery(
                          searchTab.queryController.text,
                          customSpacing: searchTab.spacingValues,
                          alternativeWords: searchTab.alternativeWords,
                          searchOptions: searchTab.searchOptions,
                        ));

                        // Navigate to search screen
                        context
                            .read<NavigationBloc>()
                            .add(const NavigateToScreen(Screen.search));
                        if (Navigator.of(context).canPop()) {
                          Navigator.of(context).pop();
                        }
                        return;
                      }
                      _openBook(
                        context,
                        historyItem.book,
                        historyItem.index,
                        historyItem.commentatorsToShow,
                      );
                    },
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_forever),
                      onPressed: () {
                        context.read<HistoryBloc>().add(RemoveHistory(index));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('נמחק בהצלחה')),
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
                  context.read<HistoryBloc>().add(ClearHistory());
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('כל ההיסטוריה נמחקה')),
                  );
                },
                child: const Text('מחק את כל ההיסטוריה'),
              ),
            ),
          ],
        );
      },
    );
  }
}
