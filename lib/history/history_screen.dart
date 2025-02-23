import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:otzaria/history/bloc/history_bloc.dart';
import 'package:otzaria/utils/open_book.dart';

class HistoryView extends StatelessWidget {
  const HistoryView({Key? key}) : super(key: key);

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
                  title: Text(state.history[index].ref),
                  onTap: () {
                    openBook(context, state.history[index].book, index, '');
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
