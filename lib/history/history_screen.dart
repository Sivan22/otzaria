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
import 'package:otzaria/tabs/bloc/tabs_event.dart';
import 'package:otzaria/tabs/models/pdf_tab.dart';
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
                itemBuilder: (context, index) => ListTile(
                  leading: state.history[index].book is PdfBook
                      ? const Icon(Icons.picture_as_pdf)
                      : null,
                  title: Text(state.history[index].ref),
                  onTap: () {
                    _openBook(
                        context,
                        state.history[index].book,
                        state.history[index].index,
                        state.history[index].commentatorsToShow);
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
                ),
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
